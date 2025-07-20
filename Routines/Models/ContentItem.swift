import Foundation
import UIKit

struct ContentItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var markdownContent: String
    var createdAt: Date
    var updatedAt: Date
    var isCompleted: Bool
    var completedAt: Date? // 新增：完成时间
    var deadline: Date? // 新增：截止日期
    var date: Date // 新增：事项归属日期
    var category: DailyView.DailyCategory // 新增：事项分类
    
    // 图片数据（存储为Base64字符串）
    var imageDataStrings: [String]
    
    init(title: String = "", content: String = "", markdownContent: String = "", date: Date = Date(), category: DailyView.DailyCategory = .todo) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.markdownContent = markdownContent
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isCompleted = false
        self.completedAt = nil
        self.deadline = nil
        self.date = date
        self.category = category
        self.imageDataStrings = []
    }
    
    // 计算属性：从Base64字符串获取图片
    var images: [UIImage] {
        return imageDataStrings.compactMap { base64String in
            guard let data = Data(base64Encoded: base64String),
                  let image = UIImage(data: data) else { return nil }
            return image
        }
    }
    
    // 计算属性：完成所用时间
    var completionDuration: TimeInterval? {
        guard isCompleted, let completedAt = completedAt else { return nil }
        return completedAt.timeIntervalSince(createdAt)
    }
    
    // 新增：完成时进度百分比
    var completionProgress: Double {
        guard let deadline = deadline else { return 0.0 }
        let totalDuration = deadline.timeIntervalSince(createdAt)
        if totalDuration <= 0 { return 0.0 }
        if isCompleted, let completedAt = completedAt {
            let finished = completedAt.timeIntervalSince(createdAt)
            let percent = finished / totalDuration
            return max(0.0, min(1.0, percent))
        } else {
            let now = Date()
            let elapsed = now.timeIntervalSince(createdAt)
            let percent = elapsed / totalDuration
            return max(0.0, min(1.0, percent))
        }
    }
    
    // 新增：检查是否已过期
    var isOverdue: Bool {
        guard let deadline = deadline else { return false }
        return Date() > deadline && !isCompleted
    }
    
    // 新增：获取剩余时间
    var remainingTime: TimeInterval? {
        guard let deadline = deadline else { return nil }
        let now = Date()
        return max(0, deadline.timeIntervalSince(now))
    }
    
    // 新增：格式化剩余时间
    func formattedRemainingTime() -> String? {
        guard let remaining = remainingTime else { return nil }
        
        let days = Int(remaining) / 86400
        let hours = Int(remaining) % 86400 / 3600
        let minutes = Int(remaining) % 3600 / 60
        
        if days > 0 {
            return "\(days)天\(hours)小时"
        } else if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "\(minutes)分钟"
        } else {
            return "已过期"
        }
    }
    
    // 新增：计算超时时间
    var overtimeDuration: TimeInterval? {
        guard isCompleted, let completedAt = completedAt, let deadline = deadline else { return nil }
        let overtime = completedAt.timeIntervalSince(deadline)
        return overtime > 0 ? overtime : nil
    }
    
    // 新增：格式化超时时间
    func formattedOvertime() -> String? {
        guard let overtime = overtimeDuration else { return nil }
        
        let days = Int(overtime) / 86400
        let hours = Int(overtime) % 86400 / 3600
        let minutes = Int(overtime) % 3600 / 60
        
        if days > 0 {
            return "超时\(days)天\(hours)小时"
        } else if hours > 0 {
            return "超时\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "超时\(minutes)分钟"
        } else {
            return "超时\(Int(overtime))秒"
        }
    }
    
    // 格式化完成所用时间
    func formattedCompletionDuration() -> String? {
        guard let duration = completionDuration else { return nil }
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "\(minutes)分钟\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
    
    // 添加图片
    mutating func addImage(_ image: UIImage) {
        // 使用 DataManager 处理图片分辨率
        let processedImage = DataManager.shared.processImage(image)
        guard let imageData = processedImage.jpegData(compressionQuality: 0.8) else { return }
        let base64String = imageData.base64EncodedString()
        imageDataStrings.append(base64String)
        updatedAt = Date()
    }
    
    // 移除图片
    mutating func removeImage(at index: Int) {
        guard index < imageDataStrings.count else { return }
        imageDataStrings.remove(at: index)
        updatedAt = Date()
    }
    
    // 标记为完成
    mutating func markAsCompleted() {
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
    }
    
    // 标记为未完成
    mutating func markAsIncomplete() {
        isCompleted = false
        completedAt = nil
        updatedAt = Date()
    }
    
    // 新增：设置截止日期
    mutating func setDeadline(_ date: Date?) {
        deadline = date
        updatedAt = Date()
    }
}

// 时间维度枚举
enum TimeDimension: String, CaseIterable {
    case daily = "一日"
    case weekly = "一周"
    case monthly = "一月"
    case yearly = "一年"
}

// 时间维度数据模型
struct TimeDimensionData: Identifiable, Codable {
    let id: UUID
    let dimension: TimeDimension
    var contentItems: [ContentItem]
    var lastModified: Date
    
    init(dimension: TimeDimension) {
        self.id = UUID()
        self.dimension = dimension
        self.contentItems = []
        self.lastModified = Date()
    }
    
    // 自定义编码解码以处理 TimeDimension 枚举
    enum CodingKeys: String, CodingKey {
        case id, dimension, contentItems, lastModified
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let dimensionString = try container.decode(String.self, forKey: .dimension)
        dimension = TimeDimension(rawValue: dimensionString) ?? .daily
        contentItems = try container.decode([ContentItem].self, forKey: .contentItems)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(dimension.rawValue, forKey: .dimension)
        try container.encode(contentItems, forKey: .contentItems)
        try container.encode(lastModified, forKey: .lastModified)
    }
} 