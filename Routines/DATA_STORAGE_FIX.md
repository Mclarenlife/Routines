# 数据存储修复技术文档

## 问题描述

应用出现以下错误：
```
CFPrefsPlistSource<0x10496cf00> (Domain: Mclarenlife.Routines, User: kCFPreferencesCurrentUser, ByHost: No, Container: (null), Contents Need Refresh: No): Attempting to store >= 4194304 bytes of data in CFPreferences/NSUserDefaults on this platform is invalid. This is a bug in Routines or a library it uses.
Description of keys being set:
dailyData: data value, size: 12731195
```

## 问题分析

### 根本原因
- **NSUserDefaults 限制**: iOS 中 NSUserDefaults 有 4MB (4,194,304 bytes) 的数据大小限制
- **数据过大**: 当前 dailyData 大小为 12,731,195 bytes (约12.7MB)，远超限制
- **图片数据**: 大量图片数据导致 JSON 编码后的数据体积过大

### 影响范围
- 数据无法保存到 NSUserDefaults
- 应用可能崩溃或数据丢失
- 用户体验严重受损

## 解决方案

### 1. 存储方式迁移
将数据存储从 NSUserDefaults 迁移到文件系统：

```swift
// 旧方式：NSUserDefaults
private let userDefaults = UserDefaults.standard
userDefaults.set(encoded, forKey: "dailyData")

// 新方式：文件系统
private var dailyDataURL: URL { documentsPath.appendingPathComponent("dailyData.json") }
try? encoded.write(to: dailyDataURL)
```

### 2. 文件路径管理
```swift
private let documentsPath: String
private var dailyDataURL: URL { documentsPath.appendingPathComponent("dailyData.json") }
private var weeklyDataURL: URL { documentsPath.appendingPathComponent("weeklyData.json") }
private var monthlyDataURL: URL { documentsPath.appendingPathComponent("monthlyData.json") }
private var yearlyDataURL: URL { documentsPath.appendingPathComponent("yearlyData.json") }
```

### 3. 数据迁移功能
自动检测并迁移旧的 NSUserDefaults 数据：

```swift
func migrateFromUserDefaultsIfNeeded() {
    let userDefaults = UserDefaults.standard
    
    if userDefaults.object(forKey: "dailyData") != nil {
        // 迁移数据到文件系统
        // 清理旧的 NSUserDefaults 数据
    }
}
```

## 技术实现

### 数据加载
```swift
private func loadData() {
    // 从文件系统加载数据
    if let data = try? Data(contentsOf: dailyDataURL),
       let decoded = try? JSONDecoder().decode(TimeDimensionData.self, from: data) {
        dailyData = decoded
    }
}
```

### 数据保存
```swift
private func saveData() {
    // 保存到文件系统
    if let encoded = try? JSONEncoder().encode(dailyData) {
        try? encoded.write(to: dailyDataURL)
    }
}
```

### 数据清理
```swift
private func clearOldUserDefaultsData() {
    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: "dailyData")
    userDefaults.removeObject(forKey: "weeklyData")
    userDefaults.removeObject(forKey: "monthlyData")
    userDefaults.removeObject(forKey: "yearlyData")
    userDefaults.synchronize()
}
```

## 优势对比

### 文件系统存储优势
- ✅ **无大小限制**: 文件系统没有 4MB 限制
- ✅ **性能更好**: 大文件读写性能优于 NSUserDefaults
- ✅ **数据隔离**: 每个时间维度独立文件，便于管理
- ✅ **备份支持**: 文件系统数据会被 iCloud 备份
- ✅ **调试友好**: 可以直接查看 JSON 文件内容

### NSUserDefaults 劣势
- ❌ **4MB 限制**: 无法存储大量数据
- ❌ **性能问题**: 大数据读写性能差
- ❌ **数据混合**: 所有数据存储在一个 plist 文件中
- ❌ **调试困难**: 二进制格式，难以直接查看

## 数据迁移流程

### 1. 检测旧数据
应用启动时检查 NSUserDefaults 中是否存在旧数据

### 2. 数据迁移
将 NSUserDefaults 中的数据读取并保存到文件系统

### 3. 清理旧数据
删除 NSUserDefaults 中的旧数据，释放空间

### 4. 验证迁移
确保数据迁移成功，应用正常运行

## 错误处理

### 文件操作错误
```swift
// 使用 try? 避免应用崩溃
if let encoded = try? JSONEncoder().encode(dailyData) {
    try? encoded.write(to: dailyDataURL)
}
```

### 数据损坏处理
```swift
// 如果文件损坏，使用默认数据
if let data = try? Data(contentsOf: dailyDataURL),
   let decoded = try? JSONDecoder().decode(TimeDimensionData.self, from: data) {
    dailyData = decoded
} else {
    // 使用默认数据
    dailyData = TimeDimensionData(dimension: .daily)
}
```

## 性能优化

### 1. 异步保存
考虑在后台线程进行数据保存操作

### 2. 增量更新
只保存发生变化的数据，而不是整个数据结构

### 3. 数据压缩
对于图片数据，考虑压缩存储

### 4. 缓存机制
添加内存缓存，减少文件 I/O 操作

## 测试建议

### 功能测试
1. **数据迁移测试**: 验证旧数据正确迁移
2. **大文件测试**: 测试大量图片数据的存储
3. **错误恢复测试**: 测试文件损坏时的恢复机制
4. **性能测试**: 测试数据加载和保存性能

### 边界测试
1. **磁盘空间不足**: 测试磁盘空间不足时的处理
2. **文件权限问题**: 测试文件权限被拒绝时的处理
3. **并发访问**: 测试多线程同时访问数据的情况

## 监控和日志

### 添加日志记录
```swift
print("🔄 开始从 UserDefaults 迁移数据到文件系统...")
print("✅ 每日数据迁移完成")
print("🎉 数据迁移完成")
```

### 性能监控
- 记录数据加载时间
- 监控文件大小变化
- 跟踪数据迁移成功率

## 后续优化

### 1. 数据压缩
实现数据压缩功能，减少存储空间

### 2. 增量备份
实现增量备份机制，只备份变化的数据

### 3. 数据版本管理
添加数据版本管理，支持数据格式升级

### 4. 云端同步
考虑添加 iCloud 同步功能

## 总结

通过将数据存储从 NSUserDefaults 迁移到文件系统，成功解决了数据过大导致的存储问题。新的存储方式具有更好的性能、更大的容量和更强的可靠性，为应用的长期发展奠定了良好的基础。 