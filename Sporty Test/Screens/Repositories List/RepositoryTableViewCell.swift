import UIKit

final class RepositoryTableViewCell: UITableViewCell {
    
    var name: String? {
        get { nameLabel.text }
        set {
            nameLabel.text = newValue
            setNeedsUpdateConstraints()
        }
    }

    var descriptionText: String? {
        get { descriptionLabel.text }
        set { descriptionLabel.text = newValue }
    }

    var starCountText: String? {
        get { starCountLabel.text }
        set {
            starCountLabel.text = newValue
            setNeedsUpdateConstraints()
        }
    }

    private let nameLabel: UILabel = {
        let label = UILabel()
        let baseFont = UIFont.preferredFont(forTextStyle: .body)
        let boldDescriptor = baseFont.fontDescriptor.withSymbolicTraits(.traitBold)
        label.font = boldDescriptor.flatMap { UIFont(descriptor: $0, size: 0) } ?? baseFont
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let starImageView: UIImageView = {
        let imageView = UIImageView()
        let configuration = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .caption1))
        imageView.image = UIImage(systemName: "star.fill", withConfiguration: configuration)
        imageView.tintColor = .systemYellow
        return imageView
    }()

    private let starCountLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize, weight: .regular)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let starsContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    private var inlineConstraints: [NSLayoutConstraint] = []
    private var stackedConstraints: [NSLayoutConstraint] = []
    private var isStacked = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        starsContainer.addArrangedSubview(starImageView)
        starsContainer.addArrangedSubview(starCountLabel)

        contentView.addSubview(nameLabel)
        contentView.addSubview(starsContainer)
        contentView.addSubview(descriptionLabel)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        starsContainer.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Shared constraints (always active)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            nameLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: contentView.layoutMarginsGuide.topAnchor, multiplier: 1),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            
            contentView.layoutMarginsGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: descriptionLabel.lastBaselineAnchor, multiplier: 1),
        ])
        
        // Inline layout: stars next to title
        inlineConstraints = [
            starsContainer.leadingAnchor.constraint(equalToSystemSpacingAfter: nameLabel.trailingAnchor, multiplier: 1),
            starsContainer.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            starsContainer.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: starsContainer.leadingAnchor, constant: -8),
            descriptionLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: nameLabel.lastBaselineAnchor, multiplier: 1),
        ]
        
        // Stacked layout: stars below title
        stackedConstraints = [
            nameLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            starsContainer.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            starsContainer.topAnchor.constraint(equalToSystemSpacingBelow: nameLabel.bottomAnchor, multiplier: 0.5),
            descriptionLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: starsContainer.bottomAnchor, multiplier: 1),
        ]
        
        NSLayoutConstraint.activate(inlineConstraints)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        let shouldStack = needsStackedLayout()
        
        if shouldStack != isStacked {
            if shouldStack {
                NSLayoutConstraint.deactivate(inlineConstraints)
                NSLayoutConstraint.activate(stackedConstraints)
            } else {
                NSLayoutConstraint.deactivate(stackedConstraints)
                NSLayoutConstraint.activate(inlineConstraints)
            }
            isStacked = shouldStack
        }
        
        super.updateConstraints()
    }
    
    private func needsStackedLayout() -> Bool {
        let availableWidth = contentView.bounds.width - contentView.layoutMargins.left - contentView.layoutMargins.right
        guard availableWidth > 0 else { return false }
        
        let nameSize = nameLabel.intrinsicContentSize
        let starsSize = starsContainer.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let spacing: CGFloat = 16
        
        return (nameSize.width + starsSize.width + spacing) > availableWidth
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isStacked = false
        NSLayoutConstraint.deactivate(stackedConstraints)
        NSLayoutConstraint.activate(inlineConstraints)
    }
}
