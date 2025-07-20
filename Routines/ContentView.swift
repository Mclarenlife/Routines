import SwiftUI

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showingSettings = false
    
    private let timeDimensions = ["一日", "一周", "一月", "一年"]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 顶部标题栏
                titleBar
                
                // 轮播内容区域
                TabView(selection: $currentIndex) {
                    DailyView()
                        .tag(0)
                    
                    WeeklyView()
                        .tag(1)
                    
                    MonthlyView()
                        .tag(2)
                    
                    YearlyView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private var titleBar: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Routines")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // 时间维度指示器
            HStack(spacing: 0) {
                ForEach(0..<timeDimensions.count, id: \.self) { index in
                    Button(action: {
                        withAnimation {
                            currentIndex = index
                        }
                    }) {
                        Text(timeDimensions[index])
                            .font(.headline)
                            .fontWeight(currentIndex == index ? .bold : .medium)
                            .foregroundColor(currentIndex == index ? .primary : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(currentIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 10)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
} 