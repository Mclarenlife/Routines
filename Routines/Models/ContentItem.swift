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
    
    // 图片数据（存储为Base64字符串）
    var imageDataStrings: [String]
    
    init(title: String = "", content: String = "", markdownContent: String = "") {
        self.id = UUID()
        self.title = title
        self.content = content
        self.markdownContent = markdownContent
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isCompleted = false
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
    
    // 添加图片
    mutating func addImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
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