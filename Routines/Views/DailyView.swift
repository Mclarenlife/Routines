import SwiftUI

struct DailyView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showingAddSheet = false
    @State private var selectedCategory: DailyCategory = .todo
    
    enum DailyCategory: String, CaseIterable {
        case todo = "待办事项"
        case routine = "每日常规"
        case diary = "日记"
        
        var icon: String {
            switch self {
            case .todo: return "checklist"
            case .routine: return "repeat"
            case .diary: return "book"
            }
        }
        
        var color: Color {
            switch self {
            case .todo: return .blue
            case .routine: return .green
            case .diary: return .orange
            }
        }
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
            AddContentView(category: selectedCategory, dimension: .daily)
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
    
    private var contentList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let items = dataManager.dailyData.contentItems.filter { item in
                    // 根据标题或内容判断分类
                    item.title.contains(selectedCategory.rawValue) || 
                    item.content.contains(selectedCategory.rawValue)
                }
                
                if items.isEmpty {
                    emptyStateView
                } else {
                    ForEach(items) { item in
                        ContentItemCard(item: item, dimension: .daily)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 80) // 为浮动按钮留出空间
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
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(item.title.isEmpty ? "无标题" : item.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if item.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
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
                
                HStack {
                    Text(item.updatedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        var updatedItem = item
                        updatedItem.isCompleted.toggle()
                        dataManager.updateContentItem(updatedItem, in: dimension)
                    }) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(item.isCompleted ? .green : .gray)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ContentDetailView(item: item, dimension: dimension)
        }
    }
}

#Preview {
    DailyView()
} 