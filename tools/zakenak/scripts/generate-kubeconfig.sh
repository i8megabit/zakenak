#!/bin/bash
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# 
# This file is part of Ƶakenak™® project.
# https://github.com/i8megabit/zakenak
#
# This program is free software and is released under the terms of the MIT License.
# See LICENSE.md file in the project root for full license information.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#
# TRADEMARK NOTICE:
# Ƶakenak™® and the Ƶakenak logo are registered trademarks of Mikhail Eberil.
# All rights reserved. The Ƶakenak trademark and brand may not be used in any way 
# without express written permission from the trademark owner.

set -e

# Получение данных из текущего контекста
CURRENT_CONTEXT=$(kubectl config current-context)
CLUSTER_NAME="kind-zakenak"
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
CLIENT_CERT_DATA=$(kubectl config view --minify --flatten -o jsonpath='{.users[0].user.client-certificate-data}')
CLIENT_KEY_DATA=$(kubectl config view --minify --flatten -o jsonpath='{.users[0].user.client-key-data}')

# Создание нового kubeconfig
cat > kubeconfig.yaml << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: ${CLUSTER_SERVER}
    certificate-authority-data: ${CA_DATA}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: ${CLUSTER_NAME}
  name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
preferences: {}
users:
- name: ${CLUSTER_NAME}
  user:
    client-certificate-data: ${CLIENT_CERT_DATA}
    client-key-data: ${CLIENT_KEY_DATA}
EOF

echo "Kubeconfig успешно создан в kubeconfig.yaml"
echo "Теперь вы можете добавить его в секреты GitHub Actions как KUBECONFIG"