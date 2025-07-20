import SwiftUI

struct YearlyView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedMonth: YearMonth = .january
    @State private var showingAddSheet = false
    
    enum YearMonth: String, CaseIterable {
        case january = "1月"
        case february = "2月"
        case march = "3月"
        case april = "4月"
        case may = "5月"
        case june = "6月"
        case july = "7月"
        case august = "8月"
        case september = "9月"
        case october = "10月"
        case november = "11月"
        case december = "12月"
        
        var icon: String {
            switch self {
            case .january: return "1.circle.fill"
            case .february: return "2.circle.fill"
            case .march: return "3.circle.fill"
            case .april: return "4.circle.fill"
            case .may: return "5.circle.fill"
            case .june: return "6.circle.fill"
            case .july: return "7.circle.fill"
            case .august: return "8.circle.fill"
            case .september: return "9.circle.fill"
            case .october: return "10.circle.fill"
            case .november: return "11.circle.fill"
            case .december: return "12.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .january: return .red
            case .february: return .pink
            case .march: return .orange
            case .april: return .yellow
            case .may: return .green
            case .june: return .mint
            case .july: return .cyan
            case .august: return .blue
            case .september: return .indigo
            case .october: return .purple
            case .november: return .brown
            case .december: return .gray
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 月份选择器
                monthSelector
                
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
                                    .fill(selectedMonth.color)
                                    .shadow(color: selectedMonth.color.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddContentView(category: selectedMonth, dimension: .yearly)
        }
    }
    
    private var monthSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(YearMonth.allCases, id: \.self) { month in
                    Button(action: {
                        selectedMonth = month
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: month.icon)
                                .font(.title3)
                                .foregroundColor(selectedMonth == month ? .white : month.color)
                            
                            Text(month.rawValue)
                                .font(.caption)
                                .foregroundColor(selectedMonth == month ? .white : .primary)
                        }
                        .frame(width: 60, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedMonth == month ? month.color : Color(.systemGray6))
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
                let items = dataManager.yearlyData.contentItems.filter { item in
                    // 根据标题或内容判断月份
                    item.title.contains(selectedMonth.rawValue) || 
                    item.content.contains(selectedMonth.rawValue)
                }
                
                if items.isEmpty {
                    emptyStateView
                } else {
                    ForEach(items) { item in
                        ContentItemCard(item: item, dimension: .yearly)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 80) // 为浮动按钮留出空间
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedMonth.icon)
                .font(.system(size: 48))
                .foregroundColor(selectedMonth.color.opacity(0.6))
            
            Text("暂无\(selectedMonth.rawValue)内容")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击下方按钮添加新的\(selectedMonth.rawValue)内容")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    

}

#Preview {
    YearlyView()
} 