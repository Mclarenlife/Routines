# Routines - 时间管理iOS应用

## 项目概述

Routines是一个功能强大的时间管理iOS应用，帮助用户高效管理每日、每周、每月、每年的任务与待办事项。应用采用现代化的UI设计，提供直观的时间维度管理体验。

## 核心功能需求

### 1. 内容编辑系统
- **Markdown支持**: 支持Markdown语法编写内容
- **模式切换**: 编辑模式与阅读模式无缝切换
- **多媒体支持**: 支持图片添加，自动读取系统相册
- **智能导入**: 导入内容自动转换为Markdown格式

### 2. 时间维度管理
应用分为四个主要时间维度，采用轮播卡片式界面设计：

#### 2.1 一日视图
- 待办事项
- 每日常规
- 日记

#### 2.2 一周视图
- 周一至周日（7个独立模块）

#### 2.3 一月视图
- 上旬
- 中旬
- 下旬

#### 2.4 一年视图
- 1月至12月（12个独立模块）

## 技术实现方案

### 架构设计
- **MVVM架构**: 采用Model-View-ViewModel设计模式
- **SwiftUI**: 使用现代SwiftUI框架构建用户界面
- **Core Data**: 本地数据持久化存储
- **Combine**: 响应式编程框架

### 核心组件
1. **ContentView**: 主容器视图，管理四个时间维度
2. **TimeDimensionView**: 时间维度视图基类
3. **ContentEditor**: 通用内容编辑器组件
4. **MarkdownRenderer**: Markdown渲染引擎
5. **ImagePicker**: 图片选择器组件
6. **DataManager**: 数据管理核心类

### 数据模型
```swift
// 基础内容模型
struct ContentItem {
    let id: UUID
    var title: String
    var content: String
    var markdownContent: String
    var images: [UIImage]
    var createdAt: Date
    var updatedAt: Date
}

// 时间维度模型
enum TimeDimension {
    case daily
    case weekly
    case monthly
    case yearly
}
```

## 开发计划

### 第一阶段：基础架构搭建
1. 创建项目基础结构
2. 实现MVVM架构框架
3. 设计数据模型
4. 搭建Core Data存储层

### 第二阶段：核心功能开发
1. 实现内容编辑系统
2. 集成Markdown渲染
3. 开发图片选择功能
4. 实现数据持久化

### 第三阶段：界面开发
1. 实现轮播卡片式主界面
2. 开发四个时间维度视图
3. 实现左右滑动切换功能
4. 优化UI/UX体验

### 第四阶段：功能完善
1. 添加内容导入导出
2. 实现数据同步
3. 性能优化
4. 测试与调试

## 技术栈

- **开发语言**: Swift 5.0+
- **UI框架**: SwiftUI
- **数据存储**: Core Data
- **响应式编程**: Combine
- **Markdown渲染**: 自定义渲染引擎
- **图片处理**: Photos Framework
- **最低支持**: iOS 14.0+

## 项目结构

```
Routines/
├── Models/           # 数据模型
├── Views/            # 视图层
├── ViewModels/       # 视图模型
├── Services/         # 业务服务
├── Utils/            # 工具类
├── Resources/        # 资源文件
└── Supporting Files/ # 支持文件
```

## 文档

- **[更新日志](CHANGELOG.md)** - 详细的功能更新记录和版本历史
- **[构建脚本](build.sh)** - 项目构建和语法检查脚本

## 下一步行动

1. 立即开始基础架构搭建
2. 实现ContentView主容器
3. 开发内容编辑系统核心组件
4. 逐步完善四个时间维度视图

---

*本项目采用敏捷开发方法，将持续迭代优化用户体验和功能完整性。* 