import SwiftUI
import AppKit

struct MemoirView: View {
    let session: Session
    @Environment(\.dismiss) private var dismiss
    @State private var showingExportConfirm = false

    var body: some View {
        ZStack {
            EmberTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(EmberTheme.sepia)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Memoir")
                        .font(.emberCaption)
                        .foregroundColor(EmberTheme.warmGray)
                        .textCase(.uppercase)
                        .tracking(2)

                    Spacer()

                    Button(action: exportToPDF) {
                        Label("Export PDF", systemImage: "arrow.down.doc")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(EmberTheme.sepia)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.4))

                Divider()
                    .foregroundColor(EmberTheme.amber.opacity(0.3))

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.title)
                                .font(.system(size: 32, weight: .regular, design: .serif))
                                .foregroundColor(EmberTheme.inkBrown)

                            HStack(spacing: 12) {
                                Text(session.formattedDate)
                                    .font(.emberCaption)
                                    .foregroundColor(EmberTheme.warmGray)

                                Text("·")
                                    .foregroundColor(EmberTheme.amber)

                                Text(session.formattedDuration)
                                    .font(.emberCaption)
                                    .foregroundColor(EmberTheme.warmGray)
                            }
                        }

                        // Decorative rule
                        HStack {
                            Rectangle()
                                .fill(EmberTheme.amber.opacity(0.4))
                                .frame(height: 1)
                            Image(systemName: "flame")
                                .font(.system(size: 12))
                                .foregroundColor(EmberTheme.amber)
                            Rectangle()
                                .fill(EmberTheme.amber.opacity(0.4))
                                .frame(height: 1)
                        }

                        // Memoir text
                        if let memoir = session.memoir {
                            Text(memoir)
                                .font(.system(size: 17, weight: .regular, design: .serif))
                                .foregroundColor(EmberTheme.inkBrown)
                                .lineSpacing(8)
                                .textSelection(.enabled)
                        }

                        // Transcript section (collapsible feel via secondary styling)
                        if let transcript = session.transcript {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Rectangle()
                                        .fill(EmberTheme.warmGray.opacity(0.3))
                                        .frame(height: 1)
                                    Text("Original Transcript")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(EmberTheme.warmGray)
                                        .textCase(.uppercase)
                                        .tracking(1.5)
                                        .fixedSize()
                                    Rectangle()
                                        .fill(EmberTheme.warmGray.opacity(0.3))
                                        .frame(height: 1)
                                }

                                Text(transcript)
                                    .font(.system(size: 14, weight: .regular, design: .serif))
                                    .foregroundColor(EmberTheme.warmGray)
                                    .lineSpacing(6)
                                    .italic()
                                    .textSelection(.enabled)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(48)
                    .frame(maxWidth: 720, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(minWidth: 640, minHeight: 500)
    }

    private func exportToPDF() {
        guard let memoir = session.memoir else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(session.title).pdf"
        panel.message = "Save your memoir as a PDF"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        exportSimplePDF(memoir: memoir, title: session.title, to: url)
    }

    private func exportSimplePDF(memoir: String, title: String, to url: URL) {
        // PDF coordinate origin is bottom-left, Y increases upward.
        // CoreText works natively in this space — no flipping needed.
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 72
        // Text rect: leave margins on all sides. CoreText fills from the top of this rect downward.
        let textRect = CGRect(x: margin, y: margin,
                              width: pageRect.width - margin * 2,
                              height: pageRect.height - margin * 2)

        var mediaBox = pageRect
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.paragraphSpacing = 10

        let inkColor = CGColor(red: 0.2, green: 0.14, blue: 0.08, alpha: 1)

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: CTFontCreateWithName("Georgia-Bold" as CFString, 26, nil),
            .foregroundColor: inkColor,
            .paragraphStyle: paragraphStyle
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: CTFontCreateWithName("Georgia" as CFString, 14, nil),
            .foregroundColor: inkColor,
            .paragraphStyle: paragraphStyle
        ]

        let fullText = NSMutableAttributedString()
        fullText.append(NSAttributedString(string: title + "\n\n", attributes: titleAttrs))
        fullText.append(NSAttributedString(string: memoir, attributes: bodyAttrs))

        let framesetter = CTFramesetterCreateWithAttributedString(fullText)
        var charIndex = 0
        let totalChars = fullText.length

        while charIndex < totalChars {
            context.beginPDFPage(nil)

            let path = CGPath(rect: textRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: charIndex, length: 0), path, nil)
            CTFrameDraw(frame, context)

            let visible = CTFrameGetVisibleStringRange(frame)
            charIndex += visible.length
            context.endPDFPage()
            if visible.length == 0 { break }
        }

        context.closePDF()
    }
}
