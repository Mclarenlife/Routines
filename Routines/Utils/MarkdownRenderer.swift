import Foundation
import SwiftUI

class MarkdownRenderer {
    static let shared = MarkdownRenderer()
    
    private init() {}
    
    // 解析Markdown文本为富文本
    func parseMarkdown(_ markdown: String) -> AttributedString {
        var attributedString = AttributedString(markdown)
        attributedString.foregroundColor = .primary
        return attributedString
    }
    
    // 简单的Markdown解析（用于预览）
    func parseMarkdownLines(_ markdown: String) -> [MarkdownLine] {
        let lines = markdown.components(separatedBy: .newlines)
        var result: [MarkdownLine] = []
        var i = 0
        var tableRows: [String] = []
        var inTable = false
        
        while i < lines.count {
            let line = lines[i]
            
            // 检查是否是代码块开始
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                // 如果有未处理的表格行，先处理表格
                if !tableRows.isEmpty {
                    result.append(MarkdownLine(type: .table, content: tableRows.joined(separator: "\n")))
                    tableRows.removeAll()
                    inTable = false
                }
                
                var codeBlockContent = ""
                i += 1 // 跳过开始标记
                
                // 收集代码块内容
                while i < lines.count {
                    let codeLine = lines[i]
                    if codeLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        break // 代码块结束
                    }
                    codeBlockContent += codeLine + "\n"
                    i += 1
                }
                
                // 移除最后的换行符
                if codeBlockContent.hasSuffix("\n") {
                    codeBlockContent = String(codeBlockContent.dropLast())
                }
                
                result.append(MarkdownLine(type: .codeBlock, content: codeBlockContent))
            } else {
                let parsedLine = parseLine(line)
                
                // 检查是否是表格行
                if parsedLine.type == .table || parsedLine.type == .tableSeparator {
                    if !inTable {
                        inTable = true
                    }
                    tableRows.append(line)
                } else {
                    // 如果有未处理的表格行，先处理表格
                    if !tableRows.isEmpty {
                        result.append(MarkdownLine(type: .table, content: tableRows.joined(separator: "\n")))
                        tableRows.removeAll()
                        inTable = false
                    }
                    result.append(parsedLine)
                }
            }
            
            i += 1
        }
        
        // 处理最后的表格行
        if !tableRows.isEmpty {
            result.append(MarkdownLine(type: .table, content: tableRows.joined(separator: "\n")))
        }
        
        return result
    }
    
    // 解析行内格式
    func parseInlineFormats(_ text: String) -> [MarkdownInlineElement] {
        print("🔍 解析文本: '\(text)'")
        
        var elements: [MarkdownInlineElement] = []
        var currentText = text
        
        // 解析加粗文本
        while let boldRange = currentText.range(of: "\\*\\*(.*?)\\*\\*", options: .regularExpression) {
            let beforeBold = String(currentText[..<boldRange.lowerBound])
            if !beforeBold.isEmpty {
                elements.append(MarkdownInlineElement(type: .text, content: beforeBold))
            }
            
            let boldContent = String(currentText[boldRange])
            let boldText = String(boldContent.dropFirst(2).dropLast(2))
            elements.append(MarkdownInlineElement(type: .bold, content: boldText))
            
            currentText = String(currentText[boldRange.upperBound...])
        }
        
        // 解析斜体文本
        while let italicRange = currentText.range(of: "\\*([^*\\n]+)\\*", options: .regularExpression) {
            print("📝 找到斜体匹配: '\(String(currentText[italicRange]))'")
            
            let beforeItalic = String(currentText[..<italicRange.lowerBound])
            if !beforeItalic.isEmpty {
                elements.append(MarkdownInlineElement(type: .text, content: beforeItalic))
            }
            
            let italicContent = String(currentText[italicRange])
            let italicText = String(italicContent.dropFirst().dropLast())
            elements.append(MarkdownInlineElement(type: .italic, content: italicText))
            print("✅ 添加斜体元素: '\(italicText)'")
            
            currentText = String(currentText[italicRange.upperBound...])
        }
        
        // 解析行内代码
        while let codeRange = currentText.range(of: "`(.*?)`", options: .regularExpression) {
            let beforeCode = String(currentText[..<codeRange.lowerBound])
            if !beforeCode.isEmpty {
                elements.append(MarkdownInlineElement(type: .text, content: beforeCode))
            }
            
            let codeContent = String(currentText[codeRange])
            let codeText = String(codeContent.dropFirst().dropLast())
            elements.append(MarkdownInlineElement(type: .inlineCode, content: codeText))
            
            currentText = String(currentText[codeRange.upperBound...])
        }
        
        // 解析链接
        while let linkRange = currentText.range(of: "\\[([^\\]]+)\\]\\(([^)]+)\\)", options: .regularExpression) {
            let beforeLink = String(currentText[..<linkRange.lowerBound])
            if !beforeLink.isEmpty {
                elements.append(MarkdownInlineElement(type: .text, content: beforeLink))
            }
            
            let linkContent = String(currentText[linkRange])
            if let textMatch = linkContent.range(of: "\\[([^\\]]+)\\]", options: .regularExpression),
               let urlMatch = linkContent.range(of: "\\(([^)]+)\\)", options: .regularExpression) {
                let linkText = String(linkContent[textMatch]).dropFirst().dropLast()
                let linkUrl = String(linkContent[urlMatch]).dropFirst().dropLast()
                elements.append(MarkdownInlineElement(type: .link, content: "\(linkText)|\(linkUrl)"))
            }
            
            currentText = String(currentText[linkRange.upperBound...])
        }
        
        // 解析删除线
        while let strikethroughRange = currentText.range(of: "~~(.*?)~~", options: .regularExpression) {
            let beforeStrikethrough = String(currentText[..<strikethroughRange.lowerBound])
            if !beforeStrikethrough.isEmpty {
                elements.append(MarkdownInlineElement(type: .text, content: beforeStrikethrough))
            }
            
            let strikethroughContent = String(currentText[strikethroughRange])
            let strikethroughText = String(strikethroughContent.dropFirst(2).dropLast(2))
            elements.append(MarkdownInlineElement(type: .strikethrough, content: strikethroughText))
            
            currentText = String(currentText[strikethroughRange.upperBound...])
        }
        
        // 添加剩余文本
        if !currentText.isEmpty {
            elements.append(MarkdownInlineElement(type: .text, content: currentText))
        }
        
        return elements.isEmpty ? [MarkdownInlineElement(type: .text, content: text)] : elements
    }
    
    private func parseLine(_ line: String) -> MarkdownLine {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // 检查标题
        if trimmedLine.hasPrefix("# ") {
            return MarkdownLine(type: .h1, content: String(trimmedLine.dropFirst(2)))
        } else if trimmedLine.hasPrefix("## ") {
            return MarkdownLine(type: .h2, content: String(trimmedLine.dropFirst(3)))
        } else if trimmedLine.hasPrefix("### ") {
            return MarkdownLine(type: .h3, content: String(trimmedLine.dropFirst(4)))
        }
        
        // 检查列表
        if trimmedLine.hasPrefix("- ") {
            return MarkdownLine(type: .bullet, content: String(trimmedLine.dropFirst(2)))
        } else if let _ = trimmedLine.range(of: "^\\d+\\.\\s", options: .regularExpression) {
            let content = String(trimmedLine.dropFirst(trimmedLine.prefix(while: { $0.isNumber }).count + 2))
            return MarkdownLine(type: .numbered, content: content)
        }
        
        // 检查是否包含行内格式
        if trimmedLine.contains("**") || trimmedLine.contains("*") || trimmedLine.contains("~~") || trimmedLine.contains("`") {
            return MarkdownLine(type: .text, content: trimmedLine)
        }
        
        // 检查删除线（整行删除线）
        if trimmedLine.hasPrefix("~~") && trimmedLine.hasSuffix("~~") && !trimmedLine.dropFirst(2).dropLast(2).contains("~~") {
            return MarkdownLine(type: .strikethrough, content: String(trimmedLine.dropFirst(2).dropLast(2)))
        }
        
        // 检查行内代码
        if trimmedLine.hasPrefix("`") && trimmedLine.hasSuffix("`") {
            return MarkdownLine(type: .inlineCode, content: String(trimmedLine.dropFirst().dropLast()))
        }
        
        // 检查表格
        if trimmedLine.hasPrefix("|") && trimmedLine.hasSuffix("|") {
            if trimmedLine.contains("---") {
                return MarkdownLine(type: .tableSeparator, content: trimmedLine)
            } else {
                // 检查是否是表头（第一行表格）
                return MarkdownLine(type: .table, content: trimmedLine)
            }
        }
        
        // 检查分割线
        if let _ = trimmedLine.range(of: "^-{3,}$", options: .regularExpression) {
            return MarkdownLine(type: .horizontalRule, content: trimmedLine)
        }
        
        // 检查引用
        if trimmedLine.hasPrefix("> ") {
            return MarkdownLine(type: .quote, content: String(trimmedLine.dropFirst(2)))
        }
        
        // 检查链接
        if trimmedLine.contains("[") && trimmedLine.contains("](") {
            return MarkdownLine(type: .link, content: trimmedLine)
        }
        
        // 空行
        if trimmedLine.isEmpty {
            return MarkdownLine(type: .empty, content: "")
        }
        
        // 普通文本
        return MarkdownLine(type: .text, content: trimmedLine)
    }
}

// Markdown行类型
enum MarkdownLineType {
    case h1, h2, h3
    case bullet, numbered
    case strikethrough
    case codeBlock, inlineCode
    case link, quote
    case table, tableSeparator, horizontalRule
    case text
    case empty
}

// Markdown行结构
struct MarkdownLine {
    let type: MarkdownLineType
    let content: String
}

// 行内元素类型
enum MarkdownInlineType {
    case text, bold, italic, strikethrough, inlineCode, link
}

// 行内元素结构
struct MarkdownInlineElement {
    let type: MarkdownInlineType
    let content: String
}

// 简化的MarkdownView扩展
extension MarkdownView {
    func renderLine(_ line: MarkdownLine) -> AnyView {
        switch line.type {
        case .h1:
            return AnyView(
                renderInlineTextInline(line.content)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        case .h2:
            return AnyView(
                renderInlineTextInline(line.content)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        case .h3:
            return AnyView(
                renderInlineTextInline(line.content)
                .font(.title2)
                .fontWeight(.medium)
                .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        case .bullet:
            return AnyView(
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .foregroundColor(.secondary)
                    renderInlineTextInline(line.content)
                    .font(.body)
                    Spacer()
            }
            )
        case .numbered:
            return AnyView(
            HStack(alignment: .top, spacing: 8) {
                Text("1.")
                    .foregroundColor(.secondary)
                    renderInlineTextInline(line.content)
                        .font(.body)
                    Spacer()
                }
            )
        case .strikethrough:
            return AnyView(
                renderInlineTextInline(line.content)
                    .font(.body)
                    .strikethrough()
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        case .codeBlock:
            return AnyView(renderCodeBlock(line.content))
        case .inlineCode:
            return AnyView(
            Text(line.content)
                .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            )
        case .link:
            return AnyView(
                renderInlineTextInline(line.content)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        case .quote:
            return AnyView(
                renderInlineTextInline(line.content)
                .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        case .table:
            return AnyView(renderTable(line.content))
        case .tableSeparator:
            return AnyView(EmptyView())
        case .horizontalRule:
            return AnyView(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            )
        case .text:
            return AnyView(
                renderInlineTextInline(line.content)
                .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        case .empty:
            return AnyView(
            Text("")
                .frame(height: 8)
                    .frame(maxWidth: .infinity)
            )
        }
    }
    
    func renderInlineTextInline(_ text: String) -> AnyView {
        let elements = MarkdownRenderer.shared.parseInlineFormats(text)
        
        return AnyView(
            HStack(spacing: 0) {
                ForEach(Array(elements.enumerated()), id: \.offset) { index, element in
                    renderInlineElement(element)
                }
            }
            .onAppear {
                print("🎨 渲染元素数量: \(elements.count)")
                for (index, element) in elements.enumerated() {
                    print("  [\(index)] 类型: \(element.type), 内容: '\(element.content)'")
                }
            }
        )
    }
    
    func renderInlineElement(_ element: MarkdownInlineElement) -> AnyView {
        switch element.type {
        case .text:
            return AnyView(Text(element.content))
        case .bold:
            return AnyView(Text(element.content).fontWeight(.bold))
        case .italic:
            return AnyView(
                Text(element.content)
                    .font(.system(.body, design: .serif))
                    .italic()
                    .foregroundColor(.primary)
            )
        case .strikethrough:
            return AnyView(Text(element.content).strikethrough())
        case .inlineCode:
            return AnyView(
                Text(element.content)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            )
        case .link:
            return AnyView(renderLink(element.content))
        }
    }
    
    func renderLink(_ content: String) -> AnyView {
        let components = content.components(separatedBy: "|")
        if components.count == 2 {
            let linkText = components[0]
            let linkUrlString = components[1]
            
            var finalUrlString = linkUrlString
            if !linkUrlString.hasPrefix("http://") && !linkUrlString.hasPrefix("https://") {
                finalUrlString = "https://" + linkUrlString
            }
            
            if let url = URL(string: finalUrlString) {
                return AnyView(
                    Link(linkText, destination: url)
                        .foregroundColor(.blue)
                        .underline()
                )
            } else {
                return AnyView(
                    Text(linkText)
                        .foregroundColor(.blue)
                        .underline()
                )
            }
        } else {
            return AnyView(
                Text(content)
                    .foregroundColor(.blue)
                    .underline()
            )
        }
    }
    
    func renderCodeBlock(_ content: String) -> AnyView {
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("代码块")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        )
    }
    
    func renderTable(_ content: String) -> AnyView {
        let rows = content.components(separatedBy: .newlines)
        var tableRows: [String] = []
        var hasHeader = false
        
        // 解析表格行
        for row in rows {
            let trimmedRow = row.trimmingCharacters(in: .whitespaces)
            if !trimmedRow.isEmpty {
                if trimmedRow.contains("---") {
                    hasHeader = true
                } else {
                    tableRows.append(trimmedRow)
                }
            }
        }
        
        return AnyView(
            VStack(spacing: 0) {
                ForEach(Array(tableRows.enumerated()), id: \.offset) { rowIndex, row in
                    let cells = row.components(separatedBy: "|").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    let isHeaderRow = hasHeader && rowIndex == 0
                    
                    HStack(spacing: 0) {
                        ForEach(Array(cells.enumerated()), id: \.offset) { cellIndex, cell in
                            renderTableCell(cell.trimmingCharacters(in: .whitespaces), isHeader: isHeaderRow)
                            
                            if cellIndex < cells.count - 1 {
                                Rectangle()
                                    .frame(width: 0.5)
                                    .foregroundColor(Color(.systemGray4))
                            }
                        }
                    }
                    
                    // 添加行间分隔线（除了最后一行）
                    if rowIndex < tableRows.count - 1 {
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color(.systemGray4))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray2), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        )
    }
    
    func renderTableCell(_ content: String, isHeader: Bool = false) -> AnyView {
        let elements = MarkdownRenderer.shared.parseInlineFormats(content)
        
        return AnyView(
            HStack(spacing: 0) {
                ForEach(Array(elements.enumerated()), id: \.offset) { index, element in
                    renderInlineElement(element)
                }
            }
            .font(.system(.body, design: .default))
            .fontWeight(isHeader ? .medium : .regular)
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHeader ? 
                Color(.systemGray5).opacity(0.4) : 
                Color.clear
            )
        )
    }
} 