//
//  OnboardingViewController.swift
//  pawpaw
//

import UIKit

final class OnboardingViewController: UIViewController, OnboardingViewProtocol, UITextFieldDelegate {
    var presenter: OnboardingPresenterProtocol?

    private let card = UIView()
    private let cardStack = UIStackView()
    private let artRow = UIStackView()
    /// Holds the title and body, plus invisible copies of every page's text that set its height.
    private let textArea = UIView()
    private let catFields = UIStackView()
    private let nameField = CatNameField()
    private let facePicker = CatFacePicker(perRow: 3, maxSide: Theme.scaled(64))
    private var isOnCatSetup = false

    private let titleLabel: UILabel = {
        let label = OnboardingViewController.makeLabel(size: 28)
        label.accessibilityTraits = .header
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = OnboardingViewController.makeLabel(size: 18, weight: .semibold)
        label.textColor = Theme.text.withAlphaComponent(0.85)
        return label
    }()

    private let pageDots: UIPageControl = {
        let dots = UIPageControl()
        dots.isUserInteractionEnabled = false
        dots.pageIndicatorTintColor = Theme.text.withAlphaComponent(0.3)
        dots.currentPageIndicatorTintColor = Theme.gold
        return dots
    }()

    private let nextButton: UIButton = {
        let button = Theme.filledButton(title: "Next", fontSize: 22, weight: .heavy)
        button.accessibilityIdentifier = "onboardingNextButton"
        return button
    }()

    private let skipButton: UIButton = {
        let button = Theme.plainButton(title: "Skip")
        button.accessibilityIdentifier = "onboardingSkipButton"
        return button
    }()

    private let backButton: UIButton = {
        let button = Theme.plainButton(title: "Back", image: "chevron.left")
        button.accessibilityIdentifier = "onboardingBackButton"
        return button
    }()

    private static let artSide: CGFloat = 64

    private static func makeLabel(size: CGFloat, weight: UIFont.Weight = .heavy) -> UILabel {
        let label = UILabel()
        label.font = Theme.roundedFont(size: Theme.scaled(size), weight: weight)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Theme.text
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        installBackground(theme: .wood)
        setupLayout()
        nameField.delegate = self
        facePicker.onSelect = { [weak self] face in self?.showCatArt(face) }
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        presenter?.viewDidLoad()
    }

    // MARK: Layout
    private func setupLayout() {
        artRow.axis = .horizontal
        artRow.alignment = .center
        artRow.spacing = Theme.scaled(12)
        artRow.isAccessibilityElement = false

        catFields.addArrangedSubview(nameField)
        catFields.addArrangedSubview(facePicker)
        catFields.axis = .vertical
        catFields.spacing = Theme.scaled(16)

        setupTextArea()

        // `catFields` is added only on the cat step; hiding it would squeeze its fields to zero height.
        for subview in [artRow, textArea] {
            cardStack.addArrangedSubview(subview)
        }
        cardStack.axis = .vertical
        cardStack.alignment = .center
        cardStack.spacing = Theme.scaled(20)
        cardStack.translatesAutoresizingMaskIntoConstraints = false

        Theme.styleCard(card)
        card.addSubview(cardStack)
        let inset = Theme.scaled(24)
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: inset),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -inset),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: inset),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -inset),
            // Pinned so long text wraps instead of widening the card past the screen margins.
            textArea.widthAnchor.constraint(equalTo: cardStack.widthAnchor)
        ])

        // Ends at the keyboard so the name field and buttons stay visible while typing.
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)

        // The controls stay put at the bottom; the card is centered in the space above them.
        let controls = UIStackView(arrangedSubviews: [pageDots, nextButton, skipButton])
        controls.axis = .vertical
        controls.alignment = .center
        controls.spacing = Theme.scaled(8)
        controls.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(controls)

        let cardArea = UIView()
        cardArea.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(cardArea)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.topAnchor),
            content.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            controls.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -8),
            controls.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            cardArea.bottomAnchor.constraint(equalTo: controls.topAnchor, constant: -8),
            cardArea.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            cardArea.trailingAnchor.constraint(equalTo: content.trailingAnchor)
        ])
        let scroll = embedCentered(card, maxWidth: Theme.scaled(440), in: cardArea)
        scroll.keyboardDismissMode = .interactive

        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Theme.scaled(8)),
            // Below Back even when it's hidden, so the card doesn't shift on the first page.
            cardArea.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8)
        ])
    }

    private func setupTextArea() {
        let text = makeTextStack(title: titleLabel, body: bodyLabel)
        textArea.addSubview(text)
        // Shrinks to the tallest text, which `reserveSpace(for:)` adds.
        let hug = textArea.heightAnchor.constraint(equalToConstant: 0)
        hug.priority = .defaultLow
        NSLayoutConstraint.activate([
            hug,
            text.centerYAnchor.constraint(equalTo: textArea.centerYAnchor),
            text.topAnchor.constraint(greaterThanOrEqualTo: textArea.topAnchor),
            text.bottomAnchor.constraint(lessThanOrEqualTo: textArea.bottomAnchor),
            text.leadingAnchor.constraint(equalTo: textArea.leadingAnchor),
            text.trailingAnchor.constraint(equalTo: textArea.trailingAnchor)
        ])
    }

    private func makeTextStack(title: UILabel, body: UILabel) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [title, body])
        stack.axis = .vertical
        stack.spacing = Theme.scaled(14)
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func showArt(for page: OnboardingPage) {
        artRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let side = Theme.scaled(Self.artSide)
        if let symbolName = page.symbolName {
            artRow.addArrangedSubview(makeSymbolBadge(symbolName, side: side))
            return
        }
        for name in page.imageNames {
            artRow.addArrangedSubview(makeArtImage(UIImage(named: name), side: side))
        }
    }

    private func showCatArt(_ face: CatFace) {
        artRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        artRow.addArrangedSubview(makeArtImage(UIImage(named: face.imageName), side: Theme.scaled(Self.artSide * 1.4)))
    }

    private func makeArtImage(_ image: UIImage?, side: CGFloat) -> UIImageView {
        let picture = UIImageView(image: image)
        picture.contentMode = .scaleAspectFit
        picture.widthAnchor.constraint(equalToConstant: side).isActive = true
        picture.heightAnchor.constraint(equalToConstant: side).isActive = true
        return picture
    }

    /// Looks like the in-game home button, with the hold ring drawn around it.
    private func makeSymbolBadge(_ symbolName: String, side: CGFloat) -> UIView {
        let badge = UIView()
        badge.backgroundColor = Theme.background
        badge.layer.cornerRadius = side / 2
        badge.layer.borderWidth = 4
        badge.layer.borderColor = Theme.accent.cgColor
        badge.widthAnchor.constraint(equalToConstant: side).isActive = true
        badge.heightAnchor.constraint(equalToConstant: side).isActive = true

        let symbol = UIImageView(image: UIImage(
            systemName: symbolName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: side * 0.4, weight: .bold)
        ))
        symbol.tintColor = Theme.text
        symbol.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(symbol)
        NSLayoutConstraint.activate([
            symbol.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])
        return badge
    }

    private func showCatFields() {
        guard catFields.superview == nil else { return }
        cardStack.addArrangedSubview(catFields)
        catFields.widthAnchor.constraint(equalTo: cardStack.widthAnchor).isActive = true
    }

    /// Cross-fades the card to new content; the first page appears without animation.
    private func transitionCard(_ update: @escaping () -> Void) {
        guard titleLabel.text != nil else {
            update()
            return
        }
        UIView.transition(with: card, duration: 0.25, options: .transitionCrossDissolve, animations: update)
    }

    private func showProgress(index: Int, count: Int, next: String, skip: String) {
        pageDots.numberOfPages = count
        pageDots.currentPage = index
        pageDots.accessibilityValue = "Step \(index + 1) of \(count)"
        nextButton.configuration?.title = next
        skipButton.configuration?.title = skip
        let isFirst = index == 0
        backButton.alpha = isFirst ? 0 : 1
        backButton.isEnabled = !isFirst
        backButton.accessibilityElementsHidden = isFirst
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    // MARK: Actions
    @objc private func nextTapped() {
        if isOnCatSetup {
            presenter?.didTapDone(name: nameField.text ?? "", face: facePicker.selectedFace)
        } else {
            presenter?.didTapNext()
        }
    }

    @objc private func backTapped() {
        view.endEditing(true)
        presenter?.didTapBack()
    }

    @objc private func skipTapped() {
        if isOnCatSetup {
            presenter?.didSkipCatSetup()
        } else {
            presenter?.didTapSkip()
        }
    }

    // MARK: OnboardingViewProtocol
    func reserveSpace(for pages: [OnboardingPage]) {
        for page in pages {
            let title = Self.makeLabel(size: 28)
            let body = Self.makeLabel(size: 18, weight: .semibold)
            title.text = page.title
            body.text = page.body
            let ghost = makeTextStack(title: title, body: body)
            ghost.alpha = 0
            ghost.isUserInteractionEnabled = false
            ghost.accessibilityElementsHidden = true
            textArea.addSubview(ghost)
            NSLayoutConstraint.activate([
                ghost.topAnchor.constraint(equalTo: textArea.topAnchor),
                ghost.bottomAnchor.constraint(lessThanOrEqualTo: textArea.bottomAnchor),
                ghost.leadingAnchor.constraint(equalTo: textArea.leadingAnchor),
                ghost.trailingAnchor.constraint(equalTo: textArea.trailingAnchor)
            ])
        }
    }

    func showPage(_ page: OnboardingPage, index: Int, count: Int) {
        isOnCatSetup = false
        transitionCard {
            self.showArt(for: page)
            self.titleLabel.text = page.title
            self.bodyLabel.text = page.body
            self.catFields.removeFromSuperview()
        }
        showProgress(index: index, count: count, next: "Next", skip: "Skip")
    }

    func showCatSetup(face: CatFace, index: Int, count: Int) {
        isOnCatSetup = true
        facePicker.select(face)
        transitionCard {
            self.showCatArt(face)
            self.titleLabel.text = "Who's playing?"
            self.bodyLabel.text = "Add your cat's name and pick the face that looks most like them. You can add more cats later."
            self.showCatFields()
        }
        showProgress(index: index, count: count, next: "Let's go", skip: "Skip for now")
    }

    func showNameRequired() {
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.values = [0, -8, 8, -5, 5, 0]
        shake.duration = 0.3
        nameField.layer.add(shake, forKey: "shake")
        nameField.becomeFirstResponder()
        UIAccessibility.post(notification: .announcement, argument: "Add your cat's name, or skip for now")
    }

    // MARK: UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        nameField.shouldChangeCharacters(in: range, replacementString: string)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}

@available(iOS 17.0, *)
#Preview {
    OnboardingRouter.createModule(onFinish: {})
}
