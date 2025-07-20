import SwiftUI
import PhotosUI

struct ContentEditor: View {
    @Binding var contentItem: ContentItem
    @State private var isEditMode = true
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedTextRange: NSRange = NSRange()
    @State private var textEditorText: String = ""
    @State private var showingImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var showingDeadlinePicker = false
    @State private var selectedDeadline: Date = Date()

    
    var body: some View {
        VStack(spacing: 16) {
            // 标题输入
            TextField("标题", text: $contentItem.title)
                .font(.title2)
                .fontWeight(.semibold)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // 截止日期选择器
            deadlineSelector
            
            // 按钮区域
            HStack {
                // 添加图片按钮
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("添加图片")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.accentColor.opacity(0.1))
                    )
                }
                .onChange(of: selectedImage) { _, item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                contentItem.addImage(image)
                                // 强制触发状态更新
                                contentItem.updatedAt = Date()
                            }
                        }
                    }
                }
                
                // 撤回/恢复按钮组
                HStack(spacing: 8) {
                    Button(action: {
                        // 调用文本编辑器的撤销功能
                        CustomTextEditor.undo()
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.accentColor.opacity(0.1))
                            )
                    }
                    
                    Button(action: {
                        // 调用文本编辑器的重做功能
                        CustomTextEditor.redo()
                    }) {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.accentColor.opacity(0.1))
                            )
                    }
                }
                
                Spacer()
                
                // 模式切换按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isEditMode.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isEditMode ? "eye.fill" : "pencil")
                        Text(isEditMode ? "预览" : "编辑")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.accentColor.opacity(0.1))
                    )
                }
            }
            
            // 内容区域
            if isEditMode {
                editModeView
            } else {
                previewModeView
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: contentItem.title) { _, _ in
            DispatchQueue.main.async {
                contentItem.updatedAt = Date()
            }
        }
        .onChange(of: contentItem.markdownContent) { _, _ in
            DispatchQueue.main.async {
            contentItem.updatedAt = Date()
        }
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            ImageViewer(
                images: contentItem.images,
                initialIndex: selectedImageIndex,
                isPresented: $showingImageViewer
            )
        }
    }
    
    // MARK: - Markdown工具栏
    
    private var markdownToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 标题工具
                toolbarButton(title: "H1", icon: "textformat.size.larger") {
                    insertMarkdown("# ", "")
                }
                
                toolbarButton(title: "H2", icon: "textformat.size") {
                    insertMarkdown("## ", "")
                }
                
                toolbarButton(title: "H3", icon: "textformat.size") {
                    insertMarkdown("### ", "")
                }
                
                Divider()
                    .frame(height: 20)
                
                // 文本格式工具
                toolbarButton(title: "加粗", icon: "bold") {
                    insertInlineMarkdown("**", "**")
                }
                
                toolbarButton(title: "斜体", icon: "italic") {
                    insertInlineMarkdown("*", "*")
                }
                
                toolbarButton(title: "删除线", icon: "strikethrough") {
                    insertInlineMarkdown("~~", "~~")
                }
                
                Divider()
                    .frame(height: 20)
                
                // 列表工具
                toolbarButton(title: "无序列表", icon: "list.bullet") {
                    insertMarkdown("- ", "")
                }
                
                toolbarButton(title: "有序列表", icon: "list.number") {
                    insertMarkdown("1. ", "")
                }
                
                Divider()
                    .frame(height: 20)
                
                // 代码工具
                toolbarButton(title: "行内代码", icon: "chevron.left.forwardslash.chevron.right") {
                    insertInlineMarkdown("`", "`")
                }
                
                toolbarButton(title: "代码块", icon: "doc.text") {
                    insertMarkdown("```\n", "\n```")
                }
                
                Divider()
                    .frame(height: 20)
                
                // 链接和引用
                toolbarButton(title: "链接", icon: "link") {
                    insertInlineMarkdown("[", "](url)")
                }
                
                toolbarButton(title: "引用", icon: "quote.bubble") {
                    insertMarkdown("> ", "")
                }
                
                Divider()
                    .frame(height: 20)
                
                // 表格和分割线
                toolbarButton(title: "表格", icon: "tablecells") {
                    insertMarkdown("| 列1 | 列2 | 列3 |\n|-----|-----|-----|\n| 内容1 | 内容2 | 内容3 |\n| 内容4 | 内容5 | 内容6 |", "")
                }
                
                toolbarButton(title: "分割线", icon: "minus") {
                    insertMarkdown("---", "")
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func toolbarButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func applyMarkdownToSelection(_ prefix: String, _ suffix: String) {
        let currentText = contentItem.markdownContent
        
        // 检查是否有选中的文本
        if selectedTextRange.length > 0 && selectedTextRange.location < currentText.count {
            // 有选中文本，对选中文本应用样式
            let nsString = currentText as NSString
            let selectedText = nsString.substring(with: selectedTextRange)
            
            // 创建新的文本，将选中的文本替换为带样式的文本
            let beforeSelection = nsString.substring(to: selectedTextRange.location)
            let afterSelection = nsString.substring(from: selectedTextRange.location + selectedTextRange.length)
            
            contentItem.markdownContent = beforeSelection + prefix + selectedText + suffix + afterSelection
            
            // 更新选中范围，包含新添加的标记
            selectedTextRange = NSRange(location: selectedTextRange.location, length: selectedTextRange.length + prefix.count + suffix.count)
        } else if selectedTextRange.location < currentText.count {
            // 没有选中文本，但在有效位置，在光标位置插入
            let nsString = currentText as NSString
            let beforeCursor = nsString.substring(to: selectedTextRange.location)
            let afterCursor = nsString.substring(from: selectedTextRange.location)
            
            contentItem.markdownContent = beforeCursor + prefix + suffix + afterCursor
            
            // 将光标移动到插入的标记之间
            selectedTextRange = NSRange(location: selectedTextRange.location + prefix.count, length: 0)
        } else {
            // 光标在末尾或无效位置，在末尾插入
            insertMarkdown(prefix, suffix)
        }
        
        // 触发状态更新
        contentItem.updatedAt = Date()
    }
    
    private func insertMarkdown(_ prefix: String, _ suffix: String) {
        let currentText = contentItem.markdownContent
        
        // 智能插入逻辑
        if currentText.isEmpty {
            // 如果文本为空，直接插入
            contentItem.markdownContent = prefix + suffix
        } else {
            // 如果文本不为空，在末尾添加换行符和新的标记
            let newLine = currentText.hasSuffix("\n") ? "" : "\n"
            contentItem.markdownContent = currentText + newLine + prefix + suffix
        }
        // 触发状态更新
        contentItem.updatedAt = Date()
        // 修复：插入后将光标移到文本末尾，延迟到主线程下一个循环
        DispatchQueue.main.async {
            selectedTextRange = NSRange(location: contentItem.markdownContent.count, length: 0)
        }
    }
    
    // 行内工具插入（不换行）
    private func insertInlineMarkdown(_ prefix: String, _ suffix: String) {
        let currentText = contentItem.markdownContent
        contentItem.markdownContent = currentText + prefix + suffix
        contentItem.updatedAt = Date()
        DispatchQueue.main.async {
            selectedTextRange = NSRange(location: contentItem.markdownContent.count, length: 0)
        }
    }

    private func insertTable() {
        let tableTemplate = """
        | 列1 | 列2 | 列3 |
        |-----|-----|-----|
        | 内容1 | 内容2 | 内容3 |
        | 内容4 | 内容5 | 内容6 |
        """
        
        let currentText = contentItem.markdownContent
        let newLine = currentText.isEmpty || currentText.hasSuffix("\n") ? "" : "\n"
        contentItem.markdownContent = currentText + newLine + tableTemplate
        
        contentItem.updatedAt = Date()
    }
    
    private var editModeView: some View {
        VStack(spacing: 12) {
            // Markdown工具栏
            markdownToolbar
            
            // Markdown内容编辑器
            CustomTextEditor(text: $contentItem.markdownContent, selectedRange: $selectedTextRange)
                .font(.body)
                .frame(minHeight: 200)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )

            
            // 图片区域
            if !contentItem.imageDataStrings.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(contentItem.images.enumerated()), id: \.offset) { index, image in
                            Button(action: {
                                selectedImageIndex = index
                                showingImageViewer = true
                            }) {
                                ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                                    
                                    // 删除按钮
                                    VStack {
                                        HStack {
                                            Spacer()
                                    Button(action: {
                                        contentItem.removeImage(at: index)
                                                // 强制触发状态更新
                                                contentItem.updatedAt = Date()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                            .padding(4)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var previewModeView: some View {
        VStack(spacing: 16) {
            // Markdown预览 - 占据主要空间
        ScrollView {
                MarkdownView(markdown: contentItem.markdownContent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
            // 图片预览 - 在底部显示
            if !contentItem.imageDataStrings.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                    ForEach(Array(contentItem.images.enumerated()), id: \.offset) { index, image in
                        Button(action: {
                            selectedImageIndex = index
                            showingImageViewer = true
                        }) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 截止日期选择器
    
    private var deadlineSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.accentColor)
                
                Text("完成期限")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    if contentItem.deadline != nil {
                        // 清除截止日期
                        contentItem.setDeadline(nil)
                    } else {
                        // 显示日期选择器
                        selectedDeadline = Date()
                        showingDeadlinePicker = true
                    }
                }) {
                    Text(contentItem.deadline != nil ? "清除期限" : "设置期限")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor.opacity(0.1))
                        )
                }
            }
            
            if let deadline = contentItem.deadline {
                HStack {
                    Text("截止时间：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(deadline, style: .date)
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Text(deadline, style: .time)
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    let now = Date()
                    if now > deadline && !contentItem.isCompleted {
                        Text("已过期")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                            )
                    } else if let remaining = formattedRemainingTimeForEditor(now: now, deadline: deadline) {
                        Text("剩余 \(remaining)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .sheet(isPresented: $showingDeadlinePicker) {
            NavigationView {
                VStack {
                    DatePicker(
                        "选择截止时间",
                        selection: $selectedDeadline,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .padding()
                    
                    Spacer()
                }
                .navigationTitle("设置截止时间")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") {
                            showingDeadlinePicker = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("确定") {
                            contentItem.setDeadline(selectedDeadline)
                            showingDeadlinePicker = false
                        }
                    }
                }
            }
        }
    }
    
    // 优化：编辑页面剩余时间显示逻辑
    private func formattedRemainingTimeForEditor(now: Date, deadline: Date) -> String? {
        let remaining = max(0, deadline.timeIntervalSince(now))
        let days = Int(remaining) / 86400
        let hours = Int(remaining) % 86400 / 3600
        let minutes = Int(remaining) % 3600 / 60
        if now > deadline {
            return nil
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
}

// Markdown渲染视图
struct MarkdownView: View {
    let markdown: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(MarkdownRenderer.shared.parseMarkdownLines(markdown), id: \.content) { line in
                renderLine(line)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentEditor(contentItem: .constant(ContentItem(title: "测试标题", content: "测试内容")))
} 

// MARK: - CustomTextEditor

struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    
    // 添加静态变量来存储当前活跃的textView
    static var currentTextView: UITextView?
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = UIColor.systemGray6
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        
        // 启用内置的撤回/恢复功能
        textView.allowsEditingTextAttributes = true
        
        // 设置撤销管理器
        context.coordinator.textView = textView
        
        // 设置当前活跃的textView
        CustomTextEditor.currentTextView = textView
        
        return textView
    }
    
    // 静态方法用于撤销/重做
    static func undo() {
        if let textView = currentTextView {
            textView.undoManager?.undo()
        }
    }
    
    static func redo() {
        if let textView = currentTextView {
            textView.undoManager?.redo()
        }
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        // 只在 selectedRange 变化时设置
        if uiView.selectedRange != selectedRange {
            let maxLocation = max(0, min(selectedRange.location, text.count))
            let maxLength = max(0, min(selectedRange.length, text.count - maxLocation))
            uiView.selectedRange = NSRange(location: maxLocation, length: maxLength)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextEditor
        weak var textView: UITextView?
        
        init(_ parent: CustomTextEditor) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            // 当开始编辑时，设置为当前活跃的textView
            CustomTextEditor.currentTextView = textView
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // 当结束编辑时，清除当前活跃的textView
            if CustomTextEditor.currentTextView === textView {
                CustomTextEditor.currentTextView = nil
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
        
        func undo() {
            textView?.undoManager?.undo()
        }
        
        func redo() {
            textView?.undoManager?.redo()
        }
    }
} 

// UIView扩展，用于找到第一响应者
extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }
        
        for subview in subviews {
            if let firstResponder = subview.findFirstResponder() {
                return firstResponder
            }
        }
        
        return nil
    }
}

// MARK: - ImageViewer

struct ImageViewer: View {
    let images: [UIImage]
    let initialIndex: Int
    @Binding var isPresented: Bool
    
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    init(images: [UIImage], initialIndex: Int, isPresented: Binding<Bool>) {
        self.images = images
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color.black
                .ignoresSafeArea()
            
            // 图片显示区域
            if !images.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                // 双击缩放
                                TapGesture(count: 2)
                                    .onEnded {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            if scale > 1.0 {
                                                scale = 1.0
                                                offset = .zero
                                            } else {
                                                scale = 2.0
                                            }
                                        }
                                    }
                            )
                            .gesture(
                                // 拖拽
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                            .gesture(
                                // 缩放
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1.0), 4.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                        if scale < 1.0 {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                scale = 1.0
                                                offset = .zero
                                            }
                                        }
                                    }
                            )
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
            
            // 顶部工具栏
            VStack {
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    if images.count > 1 {
                        Text("\(currentIndex + 1) / \(images.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scale = 1.0
                            offset = .zero
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .onAppear {
            currentIndex = initialIndex
        }
    }
}