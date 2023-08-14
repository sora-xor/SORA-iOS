import UIKit
import Then
import Anchorage
import SoraUI
import SoraUIKit

protocol AvailableInvitationsCellDelegate: InvitationLinkViewDelegate {
    func changeBoundedAmount(to type: InputRewardAmountType)
}

final class AvailableInvitationsCell: SoramitsuTableViewCell {

    private var delegate: AvailableInvitationsCellDelegate? {
        didSet {
            linkView.delegate = delegate
        }
    }

    // MARK: - Outlets
    private var containerView: SoramitsuView = {
        SoramitsuView().then {
            $0.sora.backgroundColor = .bgSurface
            $0.sora.cornerRadius = .extraLarge
            $0.sora.cornerMask = .all
            $0.sora.shadow = .small
            $0.sora.clipsToBounds = true
        }
    }()

    private var titleLabel: SoramitsuLabel = {
        SoramitsuLabel().then {
            $0.sora.text = R.string.localizable.referralInvitationLinkTitle(preferredLanguages: .currentLocale)
            $0.sora.textColor = .fgPrimary
            $0.sora.font = FontType.headline2
        }
    }()

    private var amountInvitationsLabel: SoramitsuLabel = {
        SoramitsuLabel().then {
            $0.sora.textColor = .fgPrimary
            $0.sora.alignment = .right
            $0.sora.font = FontType.headline2
        }
    }()

    private var linkView: InvitationLinkView = {
        InvitationLinkView().then {
            $0.sora.backgroundColor = .custom(uiColor: .clear)
        }
    }()

    private var bondedLabel: SoramitsuLabel = {
        SoramitsuLabel().then {
            $0.sora.text = R.string.localizable.walletBonded(preferredLanguages: .currentLocale)
            $0.sora.textColor = .fgSecondary
            $0.sora.font = FontType.textBoldXS
        }
    }()

    private var xorLabel: SoramitsuLabel = {
        SoramitsuLabel().then {
            $0.sora.textColor = .fgPrimary
            $0.sora.alignment = .right
            $0.sora.lineBreakMode = .byTruncatingMiddle
            $0.sora.font = FontType.textS
        }
    }()

    private lazy var getInvitationButton: SoramitsuButton = {
        SoramitsuButton().then {
            $0.sora.title = R.string.localizable.referralGetMoreInvitationButtonTitle(preferredLanguages: .currentLocale)
            $0.sora.backgroundColor = .accentPrimary
            $0.sora.cornerRadius = .circle
            $0.sora.addHandler(for: .touchUpInside) { [weak self] in
                self?.getInvitationButtonTapped()
            }
        }
    }()
    
    private lazy var unbondXorButton: SoramitsuButton = {
        SoramitsuButton().then {
            let title = SoramitsuTextItem(text: R.string.localizable.referralUnbondButtonTitle(preferredLanguages: .currentLocale),
                                          fontData: FontType.buttonM,
                                          textColor: .accentPrimary,
                                          alignment: .center)
            
            $0.sora.attributedText = title
            $0.sora.backgroundColor = .custom(uiColor: .clear)
            $0.sora.cornerRadius = .circle
            $0.sora.addHandler(for: .touchUpInside) { [weak self] in
                self?.unbondXorButtonTapped()
            }
        }
    }()

    // MARK: - Init

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
        setupHierarchy()
        setupLayout()
    }
    
    // MARK: - Setup
    
    private func setupCell() {
        sora.selectionStyle = .none
        sora.backgroundColor = .custom(uiColor: .clear)
    }
    
    private func setupHierarchy() {
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(amountInvitationsLabel)
        containerView.addSubview(linkView)
        containerView.addSubview(bondedLabel)
        containerView.addSubview(xorLabel)
        containerView.addSubview(getInvitationButton)
        containerView.addSubview(unbondXorButton)
    }
    
    private func setupLayout() {
        containerView.do {
            $0.topAnchor == contentView.topAnchor
            $0.bottomAnchor == contentView.bottomAnchor - 6
            $0.centerXAnchor == contentView.centerXAnchor
            $0.leadingAnchor == contentView.leadingAnchor + 16
        }

        titleLabel.do {
            $0.topAnchor == containerView.topAnchor + 24
            $0.leadingAnchor == containerView.leadingAnchor + 24
            $0.widthAnchor >= 100
        }

        amountInvitationsLabel.do {
            $0.topAnchor == containerView.topAnchor + 24
            $0.leadingAnchor == titleLabel.trailingAnchor + 10
            $0.trailingAnchor == containerView.trailingAnchor - 24
        }

        linkView.do {
            $0.topAnchor == titleLabel.bottomAnchor + 16
            $0.leadingAnchor == containerView.leadingAnchor + 16
            $0.centerXAnchor == containerView.centerXAnchor
            $0.heightAnchor == 56
        }

        bondedLabel.do {
            $0.topAnchor == linkView.bottomAnchor + 16
            $0.leadingAnchor == containerView.leadingAnchor + 24
            $0.widthAnchor >= 100
        }

        xorLabel.do {
            $0.trailingAnchor == containerView.trailingAnchor - 24
            $0.leadingAnchor == bondedLabel.trailingAnchor + 10
            $0.centerYAnchor == bondedLabel.centerYAnchor
        }

        getInvitationButton.do {
            $0.topAnchor == bondedLabel.bottomAnchor + 24
            $0.leadingAnchor == containerView.leadingAnchor + 24
            $0.centerXAnchor == containerView.centerXAnchor
            $0.heightAnchor == 56
        }

        unbondXorButton.do {
            $0.topAnchor == getInvitationButton.bottomAnchor + 16
            $0.leadingAnchor == containerView.leadingAnchor + 24
            $0.centerXAnchor == containerView.centerXAnchor
            $0.heightAnchor == 56
            $0.bottomAnchor == containerView.bottomAnchor - 24
        }
    }
    
    // MARK: - Methods
    
    func getInvitationButtonTapped() {
        delegate?.changeBoundedAmount(to: .bond)
    }

    func unbondXorButtonTapped() {
        delegate?.changeBoundedAmount(to: .unbond)
    }
}

extension AvailableInvitationsCell: Reusable {
    func bind(viewModel: CellViewModel) {
        guard let viewModel = viewModel as? AvailableInvitationsViewModel else { return }
        linkView.linkLabel.sora.text = "polkaswap.io/#/referral/" + viewModel.accountAddress
        amountInvitationsLabel.sora.text = "\(viewModel.invitationCount)"
        xorLabel.sora.text = "\(viewModel.bondedAmount) XOR"
        delegate = viewModel.delegate
    }
}