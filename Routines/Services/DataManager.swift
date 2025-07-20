import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var dailyData: TimeDimensionData
    @Published var weeklyData: TimeDimensionData
    @Published var monthlyData: TimeDimensionData
    @Published var yearlyData: TimeDimensionData
    
    private let fileManager = FileManager.default
    private let documentsPath: String
    
    private var dailyDataURL: URL { URL(fileURLWithPath: documentsPath).appendingPathComponent("dailyData.json") }
    private var weeklyDataURL: URL { URL(fileURLWithPath: documentsPath).appendingPathComponent("weeklyData.json") }
    private var monthlyDataURL: URL { URL(fileURLWithPath: documentsPath).appendingPathComponent("monthlyData.json") }
    private var yearlyDataURL: URL { URL(fileURLWithPath: documentsPath).appendingPathComponent("yearlyData.json") }
    
    private init() {
        // 获取文档目录路径
        documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        // 初始化数据
        self.dailyData = TimeDimensionData(dimension: .daily)
        self.weeklyData = TimeDimensionData(dimension: .weekly)
        self.monthlyData = TimeDimensionData(dimension: .monthly)
        self.yearlyData = TimeDimensionData(dimension: .yearly)
        
        // 加载保存的数据
        loadData()
        
        // 检查并迁移旧数据
        migrateFromUserDefaultsIfNeeded()
    }
    
    // MARK: - 数据持久化
    
    private func loadData() {
        // 加载每日数据
        if let data = try? Data(contentsOf: dailyDataURL),
           let decoded = try? JSONDecoder().decode(TimeDimensionData.self, from: data) {
            dailyData = decoded
        }
        
        // 加载每周数据
        if let data = try? Data(contentsOf: weeklyDataURL),
           let decoded = try? JSONDecoder().decode(TimeDimensionData.self, from: data) {
            weeklyData = decoded
        }
        
        // 加载每月数据
        if let data = try? Data(contentsOf: monthlyDataURL),
           let decoded = try? JSONDecoder().decode(TimeDimensionData.self, from: data) {
            monthlyData = decoded
        }
        
        // 加载每年数据
        if let data = try? Data(contentsOf: yearlyDataURL),
           let decoded = try? JSONDecoder().decode(TimeDimensionData.self, from: data) {
            yearlyData = decoded
        }
    }
    
    private func saveData() {
        // 保存每日数据
        if let encoded = try? JSONEncoder().encode(dailyData) {
            try? encoded.write(to: dailyDataURL)
        }
        
        // 保存每周数据
        if let encoded = try? JSONEncoder().encode(weeklyData) {
            try? encoded.write(to: weeklyDataURL)
        }
        
        // 保存每月数据
        if let encoded = try? JSONEncoder().encode(monthlyData) {
            try? encoded.write(to: monthlyDataURL)
        }
        
        // 保存每年数据
        if let encoded = try? JSONEncoder().encode(yearlyData) {
            try? encoded.write(to: yearlyDataURL)
        }
    }
    
    // MARK: - 公共方法
    
    func getData(for dimension: TimeDimension) -> TimeDimensionData {
        switch dimension {
        case .daily:
            return dailyData
        case .weekly:
            return weeklyData
        case .monthly:
            return monthlyData
        case .yearly:
            return yearlyData
        }
    }
    
    func updateData(_ data: TimeDimensionData) {
        switch data.dimension {
        case .daily:
            dailyData = data
        case .weekly:
            weeklyData = data
        case .monthly:
            monthlyData = data
        case .yearly:
            yearlyData = data
        }
        
        saveData()
    }
    
    func addContentItem(_ item: ContentItem, to dimension: TimeDimension) {
        var data = getData(for: dimension)
        data.contentItems.append(item)
        data.lastModified = Date()
        updateData(data)
        
        // 强制更新UI
        objectWillChange.send()
    }
    
    func updateContentItem(_ item: ContentItem, in dimension: TimeDimension) {
        var data = getData(for: dimension)
        if let index = data.contentItems.firstIndex(where: { $0.id == item.id }) {
            data.contentItems[index] = item
            data.lastModified = Date()
            updateData(data)
        }
    }
    
    func deleteContentItem(_ item: ContentItem, from dimension: TimeDimension) {
        var data = getData(for: dimension)
        data.contentItems.removeAll { $0.id == item.id }
        data.lastModified = Date()
        updateData(data)
    }
    
    func clearAllData() {
        dailyData = TimeDimensionData(dimension: .daily)
        weeklyData = TimeDimensionData(dimension: .weekly)
        monthlyData = TimeDimensionData(dimension: .monthly)
        yearlyData = TimeDimensionData(dimension: .yearly)
        saveData()
        
        // 清理旧的 NSUserDefaults 数据
        clearOldUserDefaultsData()
    }
    
    // MARK: - 数据迁移和清理
    
    private func clearOldUserDefaultsData() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "dailyData")
        userDefaults.removeObject(forKey: "weeklyData")
        userDefaults.removeObject(forKey: "monthlyData")
        userDefaults.removeObject(forKey: "yearlyData")
        userDefaults.synchronize()
    }
    
    // MARK: - 数据迁移
    
    func migrateFromUserDefaultsIfNeeded() {
        let userDefaults = UserDefaults.standard
        
        // 检查是否需要从 UserDefaults 迁移数据
        if userDefaults.object(forKey: "dailyData") != nil {
            print("🔄 开始从 UserDefaults 迁移数据到文件系统...")
            
            // 迁移每日数据
            if let data = userDefaults.data(forKey: "dailyData"),
               let decoded = try? JSONDecoder().decode(TimeDimensionData.self, from: data) {
                dailyData = decoded
                print("✅ 每日数据迁移完成")
            }
            
            // 迁移每周数据
            if let data = userDefaults.data(forKey: "weeklyData"),
               let decoded = try? JSONDecoder().decode(TimeDimensionData.self, from: data) {
                weeklyData = decoded
                print("✅ 每周数据迁移完成")
            }
            
            // 迁移每月数据
            if let data = userDefaults.data(forKey: "monthlyData"),
               let decoded = try? JSONDecoder().decode(TimeDimensionData.self, from: data) {
                monthlyData = decoded
                print("✅ 每月数据迁移完成")
            }
            
            // 迁移每年数据
            if let data = userDefaults.data(forKey: "yearlyData"),
               let decoded = try? JSONDecoder().decode(TimeDimensionData.self, from: data) {
                yearlyData = decoded
                print("✅ 每年数据迁移完成")
            }
            
            // 保存到文件系统
            saveData()
            
            // 清理 UserDefaults
            clearOldUserDefaultsData()
            
            print("🎉 数据迁移完成")
        }
    }
} 