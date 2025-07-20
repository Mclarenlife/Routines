import SwiftUI

struct DailyView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showingAddSheet = false
    @State private var selectedCategory: DailyCategory = .todo
    @State private var refreshTrigger = false // 用于强制刷新视图
    @State private var filterType: FilterType = .all // 新增：筛选类型
    @State private var selectedDate: Date = Date() // 新增：当前选中日期
    @State private var showDatePicker: Bool = false // 新增：控制日历弹窗
    
    enum DailyCategory: String, CaseIterable, Identifiable, Codable {
        case todo = "待办事项"
        case routine = "每日常规"
        case checkin = "每日打卡"
        case diary = "日记"
        var id: String { rawValue }
    }
    
    enum FilterType: String, CaseIterable, Identifiable {
        case all = "全部"
        case incomplete = "未完成"
        case complete = "已完成"
        var id: String { rawValue }
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
        VStack(spacing: 0) {
            // 分类选择器
            categorySelector
            
                // 内容列表 - 占据剩余空间
            contentList
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // 添加按钮 - 浮动在右下角
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(selectedCategory.color)
                                    .shadow(color: selectedCategory.color.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddContentView(category: selectedCategory, dimension: .daily, initialDate: selectedDate)
                .onDisappear {
                    // 确保数据更新后刷新视图
                    dataManager.objectWillChange.send()
                }
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(DailyCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.title2)
                                .foregroundColor(selectedCategory == category ? .white : category.color)
                            
                            Text(category.rawValue)
                                .font(.caption)
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                        }
                        .frame(width: 80, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCategory == category ? category.color : Color(.systemGray6))
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private var filterBar: some View {
        HStack(spacing: 12) {
            ForEach(FilterType.allCases) { type in
                Button(action: { filterType = type }) {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(filterType == type ? .bold : .regular)
                        .foregroundColor(filterType == type ? .white : .accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(filterType == type ? Color.accentColor : Color(.systemGray5))
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    private var dateBar: some View {
        HStack {
            Button(action: { showDatePicker = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                    Text(formattedDate(selectedDate))
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
                    .padding()
                Button("关闭") { showDatePicker = false }
                    .padding(.top, 8)
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        return formatter.string(from: date)
    }
    
    private var contentList: some View {
        VStack(spacing: 0) {
            if selectedCategory == .todo || selectedCategory == .routine || selectedCategory == .checkin {
                filterBar
            }
            dateBar
            List {
                let items = dataManager.dailyData.contentItems.filter { item in
                    item.category == selectedCategory &&
                    Calendar.current.isDate(item.date, inSameDayAs: selectedDate) &&
                    (filterType == .all || (filterType == .incomplete && !item.isCompleted) || (filterType == .complete && item.isCompleted))
                }
                if items.isEmpty {
                    emptyStateView
                } else {
                    ForEach(items) { item in
                        ContentItemCard(item: item, dimension: .daily)
                            .contextMenu {
                                Button(role: .destructive) {
                                    dataManager.deleteContentItem(item, from: .daily)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
                let hasDeadlineItems = dataManager.dailyData.contentItems.contains { item in
                    Calendar.current.isDate(item.date, inSameDayAs: selectedDate) &&
                    item.deadline != nil && !item.isCompleted
                }
                if hasDeadlineItems {
                    refreshTrigger.toggle()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedCategory.icon)
                .font(.system(size: 48))
                .foregroundColor(selectedCategory.color.opacity(0.6))
            
            Text("暂无\(selectedCategory.rawValue)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击下方按钮添加新的\(selectedCategory.rawValue)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    

}

struct ContentItemCard: View {
    let item: ContentItem
    let dimension: TimeDimension
    @StateObject private var dataManager = DataManager.shared
    @State private var showingDetail = false
    @State private var currentTime = Date() // 用于实时更新
    
    // 计算进度条颜色
    private var progressColor: Color {
        if item.isCompleted {
            // 如果超时1分钟，显示红色
            if let overtime = item.overtimeDuration, overtime >= 60 {
                return .red
            }
            return .green
        } else if isOverdue() {
            return .red
        } else if item.completionProgress > 0.8 {
            return .orange
        } else {
            return .blue
        }
    }
    
    // 计算实时进度（未完成时用于动画刷新）
    private func calculateProgress() -> Double {
        return item.completionProgress
    }
    
    // 计算实时剩余时间
    private func calculateRemainingTime() -> String? {
        guard let deadline = item.deadline else { return nil }
        
        let remaining = max(0, deadline.timeIntervalSince(currentTime))
        
        let days = Int(remaining) / 86400
        let hours = Int(remaining) % 86400 / 3600
        let minutes = Int(remaining) % 3600 / 60
        
        if currentTime > deadline {
            return "已过期"
        } else if days > 0 {
            return "\(days)天\(hours)小时"
        } else if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "\(minutes)分钟"
        } else {
            return "不到1分钟"
        }
    }
    
    // 检查是否已过期（实时）
    private func isOverdue() -> Bool {
        guard let deadline = item.deadline else { return false }
        return currentTime > deadline && !item.isCompleted
    }
    
    // 计算进度条刷新频率（秒）
    private var refreshInterval: TimeInterval {
        guard let deadline = item.deadline else { return 10 }
        let totalDuration = deadline.timeIntervalSince(item.createdAt)
        return totalDuration < 300 ? 1 : 10
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) { // 增加间距到12
            Button(action: {
                var updatedItem = item
                if updatedItem.isCompleted {
                    updatedItem.markAsIncomplete()
                } else {
                    updatedItem.markAsCompleted()
                }
                dataManager.updateContentItem(updatedItem, in: dimension)
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(item.isCompleted ? .green : .gray)
                    .padding(.leading, 8)
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            
            ZStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(item.title.isEmpty ? "无标题" : item.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        Spacer()
                    }
                    if !item.markdownContent.isEmpty {
                        Text(item.markdownContent)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    if !item.imageDataStrings.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(item.images.prefix(3).enumerated()), id: \.offset) { _, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .cornerRadius(6)
                                }
                                if item.images.count > 3 {
                                    Text("+\(item.images.count - 3)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 60, height: 60)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                    // 进度条显示
                    if let deadline = item.deadline {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.isCompleted ? "完成时进度" : "期限进度")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(calculateProgress() * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // 进度条
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // 背景条
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 4)
                                    
                                    // 进度条
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(progressColor)
                                        .frame(width: geometry.size.width * calculateProgress(), height: 4)
                                        .animation(item.isCompleted ? nil : .easeInOut(duration: 0.3), value: calculateProgress())
                                }
                            }
                            .frame(height: 4)
                            
                                                    // 时间信息
                            HStack {
                                if item.isCompleted {
                                    if let overtime = item.formattedOvertime() {
                                        // 超时完成：左边显示完成时间，右边显示超时时间
                                        if let completedAt = item.completedAt {
                                            Text("完成于：\(completedAt, style: .date) \(completedAt, style: .time)")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(overtime)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                    } else if let completedAt = item.completedAt {
                                        // 按时完成
                                        Text("完成于：\(completedAt, style: .date) \(completedAt, style: .time)")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                } else if isOverdue() {
                                    Text("已过期")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else if let remaining = calculateRemainingTime() {
                                    Text("剩余 \(remaining)")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                
                                Spacer()
                                
                                if !item.isCompleted {
                                    Text("截止：\(deadline, style: .date) \(deadline, style: .time)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingDetail = true
            }
            .sheet(isPresented: $showingDetail) {
                ContentDetailView(item: item, dimension: dimension)
            }
            .onReceive(Timer.publish(every: refreshInterval, on: .main, in: .common).autoconnect()) { _ in
                // 根据任务时长动态刷新进度条
                if item.deadline != nil && !item.isCompleted {
                    currentTime = Date()
                }
            }
        }
    }
}

extension DailyView.DailyCategory {
    var color: Color {
        switch self {
        case .todo:
            return .blue
        case .routine:
            return .green
        case .checkin:
            return .purple
        case .diary:
            return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .todo:
            return "checkmark.circle"
        case .routine:
            return "repeat.circle"
        case .checkin:
            return "target"
        case .diary:
            return "book.circle"
        }
    }
}

#Preview {
    DailyView()
} 