import SwiftUI

struct WeeklyView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedDay: WeekDay = .monday
    @State private var showingAddSheet = false
    
    enum WeekDay: String, CaseIterable {
        case monday = "周一"
        case tuesday = "周二"
        case wednesday = "周三"
        case thursday = "周四"
        case friday = "周五"
        case saturday = "周六"
        case sunday = "周日"
        
        var icon: String {
            switch self {
            case .monday: return "1.circle"
            case .tuesday: return "2.circle"
            case .wednesday: return "3.circle"
            case .thursday: return "4.circle"
            case .friday: return "5.circle"
            case .saturday: return "6.circle"
            case .sunday: return "7.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .monday: return .red
            case .tuesday: return .orange
            case .wednesday: return .yellow
            case .thursday: return .green
            case .friday: return .blue
            case .saturday: return .purple
            case .sunday: return .pink
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
        VStack(spacing: 0) {
            // 星期选择器
            weekDaySelector
            
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
                                    .fill(selectedDay.color)
                                    .shadow(color: selectedDay.color.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddContentView(category: selectedDay, dimension: .weekly, initialDate: Date())
        }
    }
    
    private var weekDaySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(WeekDay.allCases, id: \.self) { day in
                    Button(action: {
                        selectedDay = day
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: day.icon)
                                .font(.title2)
                                .foregroundColor(selectedDay == day ? .white : day.color)
                            
                            Text(day.rawValue)
                                .font(.caption)
                                .foregroundColor(selectedDay == day ? .white : .primary)
                        }
                        .frame(width: 70, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedDay == day ? day.color : Color(.systemGray6))
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
                let items = dataManager.weeklyData.contentItems.filter { item in
                    // 根据标题或内容判断星期
                    item.title.contains(selectedDay.rawValue) || 
                    item.content.contains(selectedDay.rawValue)
                }
                
                if items.isEmpty {
                    emptyStateView
                } else {
                    ForEach(items) { item in
                        ContentItemCard(item: item, dimension: .weekly)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 80) // 为浮动按钮留出空间
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedDay.icon)
                .font(.system(size: 48))
                .foregroundColor(selectedDay.color.opacity(0.6))
            
            Text("暂无\(selectedDay.rawValue)内容")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击下方按钮添加新的\(selectedDay.rawValue)内容")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    

}

#Preview {
    WeeklyView()
} 