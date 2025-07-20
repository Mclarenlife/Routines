import SwiftUI

struct AddContentView: View {
    let category: Any
    let dimension: TimeDimension
    let initialDate: Date // 新增：初始日期
    @StateObject private var dataManager = DataManager.shared
    @State private var contentItem: ContentItem
    @State private var showDatePicker = false // 新增：控制日期选择器弹窗
    @Environment(\.dismiss) private var dismiss
    
    init(category: Any, dimension: TimeDimension, initialDate: Date) {
        self.category = category
        self.dimension = dimension
        self.initialDate = initialDate
        let cat: DailyView.DailyCategory = (category as? DailyView.DailyCategory) ?? .todo
        _contentItem = State(initialValue: ContentItem(date: Self.startOfDay(initialDate), category: cat))
    }
    
    private static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题栏
                titleBar
                // 日期选择器
                dateSelector // 新增：事项日期选择
                // 内容编辑器
                ContentEditor(contentItem: $contentItem)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
    
    private var titleBar: some View {
        HStack {
            Button("取消") {
                dismiss()
            }
            .foregroundColor(.secondary)
            
            Spacer()
            
            Text(getCategoryTitle())
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button("保存") {
                saveContent()
            }
            .foregroundColor(.accentColor)
            .fontWeight(.semibold)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray4)),
            alignment: .bottom
        )
    }
    
    private var dateSelector: some View {
        HStack {
            Button(action: { showDatePicker = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                    Text(formattedDate(contentItem.date))
                        .font(.subheadline)
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
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker("选择事项日期", selection: $contentItem.date, displayedComponents: .date)
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
    
    private func getCategoryTitle() -> String {
        if let dailyCategory = category as? DailyView.DailyCategory {
            return dailyCategory.rawValue
        } else if let weekDay = category as? WeeklyView.WeekDay {
            return weekDay.rawValue
        } else if let monthPeriod = category as? MonthlyView.MonthPeriod {
            return monthPeriod.rawValue
        } else if let yearMonth = category as? YearlyView.YearMonth {
            return yearMonth.rawValue
        }
        return "新建内容"
    }
    
    private func saveContent() {
        // 不再自动添加分类前缀，标题完全由用户输入决定
        if contentItem.title.isEmpty {
            contentItem.title = "无标题"
        }
        // 保存到数据管理器
        dataManager.addContentItem(contentItem, to: dimension)
        dismiss()
    }
}

struct ContentDetailView: View {
    let item: ContentItem
    let dimension: TimeDimension
    @StateObject private var dataManager = DataManager.shared
    @State private var editableItem: ContentItem
    @State private var isEditing = false
    @State private var showingImageViewer = false
    @State private var selectedImageIndex = 0
    @Environment(\.dismiss) private var dismiss
    
    init(item: ContentItem, dimension: TimeDimension) {
        self.item = item
        self.dimension = dimension
        self._editableItem = State(initialValue: item)
    }
    
    // 计算进度条颜色
    private var progressColor: Color {
        if item.isCompleted {
            // 如果超时1分钟，显示红色
            if let overtime = item.overtimeDuration, overtime >= 60 {
                return .red
            }
            return .green
        } else if item.isOverdue {
            return .red
        } else if item.completionProgress > 0.8 {
            return .orange
        } else {
            return .blue
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题栏
                detailTitleBar
                
                // 内容区域
                if isEditing {
                    ContentEditor(contentItem: $editableItem)
                } else {
                    detailContentView
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            ImageViewer(
                images: item.images,
                initialIndex: selectedImageIndex,
                isPresented: $showingImageViewer
            )
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            // 每分钟更新一次进度，触发视图刷新
            if item.deadline != nil && !item.isCompleted {
                // 强制刷新视图以更新进度，但已完成的任务不更新
                dataManager.objectWillChange.send()
            }
        }
    }
    
    private var detailTitleBar: some View {
        HStack {
            Button("关闭") {
                dismiss()
            }
            .foregroundColor(.secondary)
            
            Spacer()
            
            Text(item.title.isEmpty ? "无标题" : item.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            Spacer()
            
            Button(isEditing ? "完成" : "编辑") {
                if isEditing {
                    // 保存更改
                    dataManager.updateContentItem(editableItem, in: dimension)
                }
                isEditing.toggle()
            }
            .foregroundColor(.accentColor)
            .fontWeight(.semibold)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray4)),
            alignment: .bottom
        )
    }
    
    // 格式化中文日期时间（精确到分钟）
    private func formatChineseDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
    
    private var detailContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题
                if !item.title.isEmpty {
                    Text(item.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Markdown内容
                if !item.markdownContent.isEmpty {
                    MarkdownView(markdown: item.markdownContent)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                
                // 图片
                if !item.imageDataStrings.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(Array(item.images.enumerated()), id: \.offset) { index, image in
                            Button(action: {
                                selectedImageIndex = index
                                showingImageViewer = true
                            }) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 元信息
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("创建时间:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatChineseDateTime(item.createdAt))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("更新时间:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatChineseDateTime(item.updatedAt))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("状态:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(item.isCompleted ? "已完成" : "未完成")
                            .font(.caption)
                            .foregroundColor(item.isCompleted ? .green : .orange)
                    }
                    
                    // 新增：完成时间信息
                    if item.isCompleted, let completedAt = item.completedAt {
                        HStack {
                            Text("完成时间:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatChineseDateTime(completedAt))
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        if let durationText = item.formattedCompletionDuration() {
                            HStack {
                                Text("完成用时:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(durationText)
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    // 新增：截止日期信息
                    if let deadline = item.deadline {
                        HStack {
                            Text("截止时间:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatChineseDateTime(deadline))
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        // 进度条
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.isCompleted ? "完成时进度" : "期限进度")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                let percent = Int(item.completionProgress * 100)
                                Text("\(percent)%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            GeometryReader { geometry in
                                let width = geometry.size.width * item.completionProgress
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(progressColor)
                                        .frame(width: width, height: 6)
                                        .animation(item.isCompleted ? nil : .easeInOut(duration: 0.3), value: item.completionProgress)
                                }
                            }
                            .frame(height: 6)
                            
                            // 时间状态
                            HStack {
                                if item.isCompleted {
                                    if let overtime = item.formattedOvertime() {
                                        // 超时完成：左边显示完成时间，右边显示超时时间
                                        if let completedAt = item.completedAt {
                                            Text("完成于：\(formatChineseDateTime(completedAt))")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                                .fontWeight(.medium)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(overtime)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                    } else if let completedAt = item.completedAt {
                                        // 按时完成
                                        Text("完成于：\(formatChineseDateTime(completedAt))")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .fontWeight(.medium)
                                    }
                                } else if item.isOverdue {
                                    Text("已过期")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .fontWeight(.medium)
                                } else if let remaining = item.formattedRemainingTime() {
                                    Text("剩余 \(remaining)")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            .padding(20)
        }
    }
}

#Preview {
    AddContentView(category: DailyView.DailyCategory.todo, dimension: .daily, initialDate: Date())
} 