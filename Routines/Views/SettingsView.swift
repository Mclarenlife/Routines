import SwiftUI

struct SettingsView: View {
    @StateObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearDataAlert = false
    
    private var resolutionDescription: String {
        switch dataManager.imageResolutionSetting {
        case .original:
            return "保持图片原始分辨率，文件较大"
        case .hd1080p:
            return "图片最大尺寸为1080p，平衡质量与文件大小"
        case .hd720p:
            return "图片最大尺寸为720p，文件较小"
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("应用信息") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                        Text("构建日期")
                        Spacer()
                        Text("2024")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("数据管理") {
                    Button(action: {
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("清除所有数据")
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.orange)
                        Text("导出数据")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.blue)
                        Text("导入数据")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Section("图片设置") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.purple)
                            Text("上传图片分辨率")
                            Spacer()
                        }
                        
                        Picker("图片分辨率", selection: $dataManager.imageResolutionSetting) {
                            ForEach(ImageResolutionSetting.allCases) { setting in
                                Text(setting.rawValue).tag(setting)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: dataManager.imageResolutionSetting) { _, newValue in
                            dataManager.saveImageResolutionSetting(newValue)
                        }
                        
                        Text(resolutionDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("关于") {
                    HStack {
                        Image(systemName: "heart")
                            .foregroundColor(.pink)
                        Text("Routines")
                        Spacer()
                        Text("时间管理应用")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                        Text("联系我们")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .alert("清除所有数据", isPresented: $showingClearDataAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                dataManager.clearAllData()
            }
        } message: {
            Text("此操作将永久删除所有内容，无法恢复。确定要继续吗？")
        }
    }
}

#Preview {
    SettingsView()
} 