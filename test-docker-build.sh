#!/bin/bash

# 测试Docker构建配置
echo "=== 测试Docker构建配置 ==="

# 检查Dockerfile是否存在
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile 不存在"
    exit 1
fi
echo "✅ Dockerfile 存在"

# 检查.dockerignore是否存在
if [ ! -f ".dockerignore" ]; then
    echo "⚠️  .dockerignore 不存在，可能影响构建性能"
else
    echo "✅ .dockerignore 存在"
fi

# 检查GitHub Actions工作流
if [ ! -f ".github/workflows/docker-build.yml" ]; then
    echo "❌ GitHub Actions工作流不存在"
    exit 1
fi
echo "✅ GitHub Actions工作流存在"

# 检查Go模块
if [ ! -f "go.mod" ]; then
    echo "❌ go.mod 不存在"
    exit 1
fi
echo "✅ go.mod 存在"

# 检查模块名称
MODULE_NAME=$(grep "^module" go.mod | awk '{print $2}')
if [ "$MODULE_NAME" != "github.com/springsunx/webssh" ]; then
    echo "❌ 模块名称不正确: $MODULE_NAME"
    exit 1
fi
echo "✅ 模块名称正确: $MODULE_NAME"

# 检查导入路径
echo "检查导入路径..."
if grep -r "github.com/yourusername" . --include="*.go" > /dev/null; then
    echo "❌ 仍存在旧的导入路径"
    exit 1
fi
echo "✅ 导入路径已修复"

# 检查Docker构建命令（如果Docker可用）
if command -v docker &> /dev/null; then
    echo "=== 测试Docker构建 ==="
    echo "正在构建Docker镜像..."
    if docker build -t webssh-test .; then
        echo "✅ Docker镜像构建成功"
        echo "正在清理测试镜像..."
        docker rmi webssh-test
    else
        echo "❌ Docker镜像构建失败"
        exit 1
    fi
else
    echo "⚠️  Docker未安装，跳过本地构建测试"
fi

echo ""
echo "=== 配置检查完成 ==="
echo "所有检查通过！GitHub Actions工作流应该能正常工作。"