import SwiftUI
import CoreGraphics

/// Renders a `GIReport` to a US Letter PDF.
///
/// Sections are measured individually and packed into pages so a block never gets sliced in
/// half by a page break.
@MainActor
enum ReportPDFRenderer {

    static let pageSize = CGSize(width: 612, height: 792) // US Letter at 72 dpi
    static let margin: CGFloat = 40

    private static var contentWidth: CGFloat { pageSize.width - margin * 2 }
    private static var contentHeight: CGFloat { pageSize.height - margin * 2 }

    static func makePDF(for report: GIReport) -> Data? {
        let pages = paginate(ReportDocument.sections(for: report))
        guard !pages.isEmpty else { return nil }

        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data) else { return nil }
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        for (index, sections) in pages.enumerated() {
            // Framing every page to exactly the content box means the rendered size always
            // matches, so an even margin offset positions it correctly regardless of which
            // way the PDF coordinate space runs.
            let page = ReportPage(sections: sections, pageNumber: index + 1, pageCount: pages.count)
                .frame(width: contentWidth, height: contentHeight, alignment: .top)

            let renderer = ImageRenderer(content: page)
            renderer.render { _, renderInContext in
                context.beginPDFPage(nil)
                context.saveGState()
                context.translateBy(x: margin, y: margin)
                renderInContext(context)
                context.restoreGState()
                context.endPDFPage()
            }
        }

        context.closePDF()
        return data as Data
    }

    /// Writes the PDF to a temporary file for sharing, returning its URL.
    static func writePDF(for report: GIReport, fileName: String) -> URL? {
        guard let data = makePDF(for: report) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Pagination

    private static func paginate(_ sections: [ReportSection]) -> [[ReportSection]] {
        var pages: [[ReportSection]] = []
        var current: [ReportSection] = []
        var currentHeight: CGFloat = 0

        for section in sections {
            let height = measuredHeight(section)
            let needed = current.isEmpty ? height : height + ReportLayout.sectionSpacing

            if !current.isEmpty && currentHeight + needed > contentHeight {
                pages.append(current)
                current = [section]
                currentHeight = height
            } else {
                current.append(section)
                currentHeight += needed
            }
        }

        if !current.isEmpty { pages.append(current) }
        return pages
    }

    private static func measuredHeight(_ section: ReportSection) -> CGFloat {
        var height: CGFloat = 0
        let renderer = ImageRenderer(content: section.view.frame(width: contentWidth))
        renderer.render { size, _ in height = size.height }
        // A section taller than a page can't be split, so clamp it rather than letting it push
        // every following section onto its own page.
        return min(height, contentHeight)
    }
}
