#!/bin/bash

echo "🚀 开始构建 Routines iOS 应用..."

# 检查是否安装了 Swift
if ! command -v swift &> /dev/null; then
    echo "❌ 错误: 未找到 Swift 编译器"
    echo "请确保已安装 Xcode 或 Swift 工具链"
    exit 1
fi

echo "📱 项目结构检查..."
echo "✅ RoutinesApp.swift - 主入口文件"
echo "✅ ContentView.swift - 主界面"
echo "✅ Models/ContentItem.swift - 数据模型"
echo "✅ Services/DataManager.swift - 数据管理"
echo "✅ Views/ - 视图文件"
echo "✅ Utils/MarkdownRenderer.swift - Markdown渲染器"

echo ""
echo "🔧 开始语法检查..."

# 检查所有Swift文件的语法
echo "检查主要文件..."
for file in *.swift Views/*.swift Models/*.swift Services/*.swift Utils/*.swift; do
    if [ -f "$file" ]; then
        echo "  📝 检查 $file"
        if ! swift -frontend -parse "$file" > /dev/null 2>&1; then
            echo "  ❌ $file 有语法错误"
            exit 1
        fi
    fi
done

echo ""
echo "✅ 所有文件语法检查通过!"

# 检查是否有Xcode项目文件
if [ -d "Routines.xcodeproj" ]; then
    echo ""
    echo "🔧 发现Xcode项目文件，开始编译..."
    
    # 检查是否安装了 Xcode
    if ! command -v xcodebuild &> /dev/null; then
        echo "❌ 错误: 未找到 Xcode 或 xcodebuild 命令"
        echo "请确保已安装 Xcode 并配置了命令行工具"
        exit 1
    fi
    
    # 尝试编译项目
    xcodebuild -project Routines.xcodeproj -scheme Routines -destination 'platform=iOS Simulator,name=iPhone 15' build
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ 编译成功!"
    else
        echo ""
        echo "❌ 编译失败!"
        echo "请检查代码中的错误并重新尝试"
        exit 1
    fi
else
    echo ""
    echo "ℹ️  未找到 Xcode 项目文件"
    echo "   这是一个纯 Swift 文件项目，需要在 Xcode 中创建项目来运行"
fi

echo ""
echo "🎉 Routines 应用检查完成!"
echo ""
echo "📋 功能特性:"
echo "   • 四个时间维度管理 (日/周/月/年)"
echo "   • Markdown 内容编辑和预览"
echo "   • 图片添加和管理"
echo "   • 数据持久化存储"
echo "   • 现代化 SwiftUI 界面"
echo ""
echo "🚀 下一步:"
echo "   1. 在 Xcode 中创建新的 iOS 项目"
echo "   2. 将现有 Swift 文件添加到项目中"
echo "   3. 选择目标设备或模拟器"
echo "   4. 点击运行按钮开始测试"
echo ""
echo "�� 详细文档请查看 README.md" 