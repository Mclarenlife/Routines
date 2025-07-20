import SwiftUI

struct MonthlyView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedPeriod: MonthPeriod = .early
    @State private var showingAddSheet = false
    
    enum MonthPeriod: String, CaseIterable {
        case early = "上旬"
        case middle = "中旬"
        case late = "下旬"
        
        var icon: String {
            switch self {
            case .early: return "1.square"
            case .middle: return "2.square"
            case .late: return "3.square"
            }
        }
        
        var color: Color {
            switch self {
            case .early: return .blue
            case .middle: return .green
            case .late: return .purple
            }
        }
        
        var description: String {
            switch self {
            case .early: return "1-10日"
            case .middle: return "11-20日"
            case .late: return "21-31日"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 时间段选择器
                periodSelector
                
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
                                    .fill(selectedPeriod.color)
                                    .shadow(color: selectedPeriod.color.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddContentView(category: selectedPeriod, dimension: .monthly)
        }
    }
    
    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(MonthPeriod.allCases, id: \.self) { period in
                    Button(action: {
                        selectedPeriod = period
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: period.icon)
                                .font(.title2)
                                .foregroundColor(selectedPeriod == period ? .white : period.color)
                            
                            Text(period.rawValue)
                                .font(.headline)
                                .foregroundColor(selectedPeriod == period ? .white : .primary)
                            
                            Text(period.description)
                                .font(.caption)
                                .foregroundColor(selectedPeriod == period ? .white.opacity(0.8) : .secondary)
                        }
                        .frame(width: 100, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedPeriod == period ? period.color : Color(.systemGray6))
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
                let items = dataManager.monthlyData.contentItems.filter { item in
                    // 根据标题或内容判断时间段
                    item.title.contains(selectedPeriod.rawValue) || 
                    item.content.contains(selectedPeriod.rawValue)
                }
                
                if items.isEmpty {
                    emptyStateView
                } else {
                    ForEach(items) { item in
                        ContentItemCard(item: item, dimension: .monthly)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 80) // 为浮动按钮留出空间
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedPeriod.icon)
                .font(.system(size: 48))
                .foregroundColor(selectedPeriod.color.opacity(0.6))
            
            Text("暂无\(selectedPeriod.rawValue)内容")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击下方按钮添加新的\(selectedPeriod.rawValue)内容")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    

}

#Preview {
    MonthlyView()
} 