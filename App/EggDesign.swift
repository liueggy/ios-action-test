import UIKit

enum EggDesign {
    static var accent: UIColor { AppSettings.shared.accentStyle.tintColor }

    static func groupedBackground() -> UIColor { .systemGroupedBackground }
    static func cardBackground() -> UIColor { .secondarySystemGroupedBackground }

    static func iconBackground(for color: UIColor) -> UIColor {
        color.withAlphaComponent(0.14)
    }

    static func applyCardShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.06
        view.layer.shadowRadius = 14
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
    }
}

final class EggCardCell: UITableViewCell {
    static let reuseIdentifier = "EggCardCell"

    private let cardView = UIView()
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let trailingLabel = UILabel()
    private let chevronView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = EggDesign.cardBackground()
        cardView.layer.cornerRadius = 20
        cardView.layer.cornerCurve = .continuous
        EggDesign.applyCardShadow(to: cardView)
        contentView.addSubview(cardView)

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 16
        iconContainer.layer.cornerCurve = .continuous
        cardView.addSubview(iconContainer)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        cardView.addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        cardView.addSubview(subtitleLabel)

        trailingLabel.translatesAutoresizingMaskIntoConstraints = false
        trailingLabel.font = .preferredFont(forTextStyle: .caption1)
        trailingLabel.textColor = .secondaryLabel
        trailingLabel.textAlignment = .right
        trailingLabel.numberOfLines = 1
        cardView.addSubview(trailingLabel)

        chevronView.translatesAutoresizingMaskIntoConstraints = false
        chevronView.tintColor = .tertiaryLabel
        cardView.addSubview(chevronView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            iconContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            iconContainer.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            chevronView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            chevronView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 10),

            trailingLabel.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -8),
            trailingLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            trailingLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 82),

            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingLabel.leadingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -42),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        trailingLabel.text = nil
        chevronView.isHidden = false
    }

    func configure(
        title: String,
        subtitle: String?,
        icon: String,
        tint: UIColor = EggDesign.accent,
        trailing: String? = nil,
        showsChevron: Bool = true
    ) {
        cardView.backgroundColor = EggDesign.cardBackground()
        titleLabel.text = title
        subtitleLabel.text = subtitle
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = tint
        iconContainer.backgroundColor = EggDesign.iconBackground(for: tint)
        trailingLabel.text = trailing
        chevronView.isHidden = !showsChevron
    }

    func setCompleted(_ completed: Bool) {
        titleLabel.textColor = completed ? .secondaryLabel : .label
        cardView.alpha = completed ? 0.72 : 1.0
    }
}
