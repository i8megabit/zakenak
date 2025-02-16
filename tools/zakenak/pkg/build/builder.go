package build

import (
    "context"
    "fmt"
    "github.com/docker/docker/api/types"
    "github.com/docker/docker/client"
    "github.com/i8meg/zakenak/pkg/config"
)

// Builder управляет процессом сборки образов
type Builder struct {
    docker *client.Client
    config *config.BuildConfig
}

// NewBuilder создает новый билдер
func NewBuilder(cfg *config.BuildConfig) (*Builder, error) {
    docker, err := client.NewClientWithOpts(client.FromEnv)
    if err != nil {
        return nil, fmt.Errorf("failed to create docker client: %w", err)
    }

    return &Builder{
        docker: docker,
        config: cfg,
    }, nil
}

// Build выполняет сборку образа
func (b *Builder) Build(ctx context.Context) error {
    buildOpts := types.ImageBuildOptions{
        Dockerfile: b.config.Dockerfile,
        Tags:      []string{b.config.Args["VERSION"]},
        BuildArgs: b.config.Args,
    }

    // Добавляем поддержку GPU если включено
    if b.config.GPU.Enabled {
        buildOpts.BuildArgs["NVIDIA_VISIBLE_DEVICES"] = b.config.GPU.Devices
        buildOpts.BuildArgs["NVIDIA_DRIVER_CAPABILITIES"] = "compute,utility"
        buildOpts.BuildArgs["NVIDIA_REQUIRE_CUDA"] = "cuda>=12.8"
    }

    // TODO: Имплементация сборки образа
    return nil
}

// Push отправляет образ в registry
func (b *Builder) Push(ctx context.Context) error {
    // TODO: Имплементация push
    return nil
}