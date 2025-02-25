
#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Checking CUDA Support in WSL...${NC}"

# Check if nvidia-smi is available
echo -e "\n${YELLOW}1. Checking NVIDIA Driver:${NC}"
if command -v nvidia-smi &> /dev/null; then
	nvidia-smi
	echo -e "${GREEN}✓ NVIDIA Driver is installed${NC}"
else
	echo -e "${RED}✗ NVIDIA Driver is not installed${NC}"
	exit 1
fi

# Check CUDA version
echo -e "\n${YELLOW}2. Checking CUDA Version:${NC}"
if command -v nvcc &> /dev/null; then
	CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
	echo -e "CUDA Version: $CUDA_VERSION"
	if (( $(echo "$CUDA_VERSION >= 12.8" | bc -l) )); then
		echo -e "${GREEN}✓ CUDA version is compatible (>= 12.8)${NC}"
	else
		echo -e "${RED}✗ CUDA version is below 12.8${NC}"
		echo -e "${YELLOW}Current version: $CUDA_VERSION${NC}"
	fi
else
	echo -e "${RED}✗ CUDA toolkit is not installed${NC}"
fi

# Check CUDA libraries

echo -e "\n${YELLOW}3. Checking CUDA Libraries:${NC}"
if [ -d "/usr/local/cuda/lib64" ]; then
	echo -e "${GREEN}✓ CUDA libraries found in /usr/local/cuda/lib64${NC}"
	ls -l /usr/local/cuda/lib64/libcud*.so* 2>/dev/null
else
	echo -e "${RED}✗ CUDA libraries not found${NC}"
fi

# Check WSL NVIDIA libraries
echo -e "\n${YELLOW}4. Checking WSL NVIDIA Libraries:${NC}"
if [ -d "/usr/lib/wsl/lib" ]; then
	echo -e "${GREEN}✓ WSL NVIDIA libraries found${NC}"
	ls -l /usr/lib/wsl/lib/libcud*.so* 2>/dev/null
else
	echo -e "${RED}✗ WSL NVIDIA libraries not found${NC}"
fi

# Test CUDA capability
echo -e "\n${YELLOW}5. Testing CUDA Capability:${NC}"
cat << EOF > /tmp/cuda_test.cu
#include <stdio.h>

int main() {
	cudaDeviceProp prop;
	int count;
	
	cudaError_t error = cudaGetDeviceCount(&count);
	if (error != cudaSuccess) {
		printf("Error: %s\n", cudaGetErrorString(error));
		return -1;
	}
	
	for (int i = 0; i < count; i++) {
		cudaGetDeviceProperties(&prop, i);
		printf("Device %d: %s\n", i, prop.name);
		printf("  Compute capability: %d.%d\n", prop.major, prop.minor);
		printf("  Total global memory: %.2f GB\n", prop.totalGlobalMem / (1024.0 * 1024.0 * 1024.0));
	}
	return 0;
}
EOF

if command -v nvcc &> /dev/null; then
	echo "Compiling CUDA test program..."
	if nvcc /tmp/cuda_test.cu -o /tmp/cuda_test; then
		echo -e "${GREEN}✓ CUDA compilation successful${NC}"
		echo "Running CUDA test..."
		/tmp/cuda_test
	else
		echo -e "${RED}✗ CUDA compilation failed${NC}"
	fi
else
	echo -e "${RED}✗ Cannot test CUDA capability - nvcc not found${NC}"
fi

# Cleanup
rm -f /tmp/cuda_test.cu /tmp/cuda_test

echo -e "\n${YELLOW}Summary:${NC}"
echo "To use CUDA 12.8 in WSL, you need:"
echo "1. NVIDIA Driver supporting CUDA 12.8"
echo "2. CUDA Toolkit 12.8 installed"
echo "3. Proper WSL2 configuration with NVIDIA support"
echo "4. GPU with appropriate compute capability"