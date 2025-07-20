import SwiftUI

struct AddContentView: View {
    let category: Any
    let dimension: TimeDimension
    @StateObject private var dataManager = DataManager.shared
    @State private var contentItem = ContentItem()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题栏
                titleBar
                
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
        // 根据分类自动设置标题前缀
        let categoryTitle = getCategoryTitle()
        if contentItem.title.isEmpty {
            contentItem.title = categoryTitle
        } else if !contentItem.title.contains(categoryTitle) {
            contentItem.title = "\(categoryTitle) - \(contentItem.title)"
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
    AddContentView(category: DailyView.DailyCategory.todo, dimension: .daily)
} 