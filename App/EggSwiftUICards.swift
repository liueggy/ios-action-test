import SwiftUI
import UIKit

struct EggHeroCardView: View {
    let greeting: String
    let modeName: String
    let completionRate: Int
    let pendingCount: Int
    let todayCount: Int
    let overdueCount: Int
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Egg Tool")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("\(greeting)，今天也保持清晰。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(10)
                    .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            HStack(spacing: 10) {
                pill("模式", modeName, icon: "person.crop.circle")
                pill("完成", "\(completionRate)%", icon: "chart.pie.fill")
            }

            HStack(spacing: 10) {
                metric("待处理", pendingCount, .primary)
                metric("今日", todayCount, accent)
                metric("逾期", overdueCount, overdueCount > 0 ? .red : .secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
    }

    private func pill(_ title: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.secondary.opacity(0.10), in: Capsule())
    }

    private func metric(_ title: String, _ value: Int, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

final class SwiftUIHeroCell: UITableViewCell {
    static let reuseIdentifier = "SwiftUIHeroCell"
    private var hostingController: UIHostingController<EggHeroCardView>?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(view: EggHeroCardView, parent: UIViewController) {
        if let hostingController {
            hostingController.rootView = view
            hostingController.view.invalidateIntrinsicContentSize()
            return
        }

        let controller = UIHostingController(rootView: view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear
        parent.addChild(controller)
        contentView.addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
        controller.didMove(toParent: parent)
        hostingController = controller
    }
}
