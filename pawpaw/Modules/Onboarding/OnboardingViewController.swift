//
//  OnboardingViewController.swift
//  pawpaw
//

import UIKit

final class OnboardingViewController: UIViewController, OnboardingViewProtocol,
    UITextFieldDelegate,
    UIGestureRecognizerDelegate
{
    var presenter: OnboardingPresenterProtocol?

    private let card = UIView()
    private let cardStack = UIStackView()
    let artRow = UIStackView()
    /// Holds the title and body, plus invisible copies of every page's text that set its height.
    private let textArea = UIView()
    private let catFields = UIStackView()
    private let nameField = CatNameField()
    private let facePicker = CatFacePicker(
        perRow: 3,
        maxSide: 64,
        minSide: Theme.minimumTapSize
    )
    let practiceArea = UIView()
    let playfield = OnboardingPlayfieldView()
    let countdown = OnboardingCountdownView()
    let holdPractice = OnboardingHoldPracticeView()
    let ambient = OnboardingAmbientView()
    var interaction: OnboardingInteraction?
    private var shownIndex: Int?
    private var progress: OnboardingProgress?
    private var skipHint = ""
    private weak var cardScroll: UIScrollView?
    /// How much of the card's scroll view the keyboard covers.
    private var keyboardInset: CGFloat = 0

    private let titleLabel: UILabel = {
        let label = OnboardingViewController.makeLabel(size: 28)
        label.accessibilityTraits = .header
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = OnboardingViewController.makeLabel(
            size: 18,
            weight: .semibold
        )
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

    let nextButton: UIButton = {
        let button = Theme.filledButton(
            title: "",
            fontSize: 22,
            weight: .heavy
        )
        button.accessibilityIdentifier = "onboardingNextButton"
        return button
    }()

    private let skipButton: UIButton = {
        let button = Theme.plainButton(title: "")
        button.accessibilityIdentifier = "onboardingSkipButton"
        return button
    }()

    private let backButton: UIButton = {
        let button = Theme.plainButton(title: "Back", image: "chevron.left")
        button.accessibilityIdentifier = "onboardingBackButton"
        return button
    }()

    private static let artSide: CGFloat = 64
    static let practiceHeight: CGFloat = 170
    static let minPracticeHeight: CGFloat = 110
    private static let cardMargin: CGFloat = 24

    // When the card is taller than the space above the buttons, the reserved text space gives way
    // first, then the art and practice area, then the face picker (just below `.defaultHigh`);
    // past that the card scrolls.
    private static let fitPriority = UILayoutPriority.defaultHigh
    static let artPriority = UILayoutPriority(650)
    private static let reservedTextPriority = UILayoutPriority(600)

    private static func makeLabel(size: CGFloat, weight: UIFont.Weight = .heavy)
        -> UILabel
    {
        let label = Theme.makeLabel(size: size, weight: weight)
        // Required, so fitting the card shrinks the art and picker rather than cutting off text.
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .menus
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        installBackground(theme: .wood)
        setupAmbient()
        setupLayout()
        setupPractice()
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        facePicker.onSelect = { [weak self] face in
            self?.showCatArt(face)
            self?.bounceCatArt()
            self?.presenter?.didSelectFace(face)
        }
        nextButton.addTarget(
            self,
            action: #selector(nextTapped),
            for: .touchUpInside
        )
        installHoldToSkip()
        backButton.addTarget(
            self,
            action: #selector(backTapped),
            for: .touchUpInside
        )
        setupSwipes()
        presenter?.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ambient.start()
        startInteraction()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ambient.stop()
        stopInteractions()
    }

    /// Swipes step through the pages like the Next and Back buttons.
    private func setupSwipes() {
        for direction in [UISwipeGestureRecognizer.Direction.left, .right] {
            let swipe = UISwipeGestureRecognizer(
                target: self,
                action: #selector(swiped(_:))
            )
            swipe.direction = direction
            swipe.delegate = self
            view.addGestureRecognizer(swipe)
        }
    }

    // MARK: Layout
    private func setupLayout() {
        artRow.axis = .horizontal
        artRow.alignment = .center
        artRow.spacing = 12
        artRow.isAccessibilityElement = false

        catFields.addArrangedSubview(nameField)
        catFields.addArrangedSubview(facePicker)
        catFields.axis = .vertical
        catFields.spacing = 16

        setupTextArea()

        // `catFields` is added only on the cat step; hiding it would squeeze its fields to zero height.
        for subview in [artRow, practiceArea, textArea] {
            cardStack.addArrangedSubview(subview)
        }
        cardStack.axis = .vertical
        cardStack.alignment = .center
        cardStack.spacing = 20
        cardStack.translatesAutoresizingMaskIntoConstraints = false

        Theme.styleCard(card)
        card.addSubview(cardStack)
        let inset: CGFloat = 24
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(
                equalTo: card.topAnchor,
                constant: inset
            ),
            cardStack.bottomAnchor.constraint(
                equalTo: card.bottomAnchor,
                constant: -inset
            ),
            cardStack.leadingAnchor.constraint(
                equalTo: card.leadingAnchor,
                constant: inset
            ),
            cardStack.trailingAnchor.constraint(
                equalTo: card.trailingAnchor,
                constant: -inset
            ),
            // Pinned so long text wraps instead of widening the card past the screen margins.
            textArea.widthAnchor.constraint(equalTo: cardStack.widthAnchor),
            practiceArea.widthAnchor.constraint(equalTo: cardStack.widthAnchor),
        ])

        // The controls stay put at the bottom; the card is centered in the space above them.
        // The keyboard slides over both rather than squeezing them; see `updateKeyboardInset()`.
        let controls = UIStackView(arrangedSubviews: [
            pageDots, nextButton, skipButton,
        ])
        controls.axis = .vertical
        controls.alignment = .center
        controls.spacing = 8
        controls.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controls)

        let cardArea = UIView()
        cardArea.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardArea)

        NSLayoutConstraint.activate([
            controls.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -8
            ),
            controls.centerXAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerXAnchor
            ),

            cardArea.bottomAnchor.constraint(
                equalTo: controls.topAnchor,
                constant: -8
            ),
            cardArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        let scroll = embedCentered(
            card,
            maxWidth: 440,
            margin: Self.cardMargin,
            in: cardArea
        )
        scroll.keyboardDismissMode = .interactive
        cardScroll = scroll

        // Invisible; follows the keyboard so its moves trigger `viewDidLayoutSubviews`.
        let keyboardTracker = UIView()
        keyboardTracker.isUserInteractionEnabled = false
        keyboardTracker.isAccessibilityElement = false
        keyboardTracker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardTracker)
        NSLayoutConstraint.activate([
            keyboardTracker.topAnchor.constraint(
                equalTo: view.keyboardLayoutGuide.topAnchor
            ),
            keyboardTracker.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            keyboardTracker.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            keyboardTracker.widthAnchor.constraint(equalToConstant: 0),
        ])
        // Keeps the card on screen on shorter phones instead of cutting it off at the buttons.
        let fit = card.heightAnchor.constraint(
            lessThanOrEqualTo: scroll.frameLayoutGuide.heightAnchor,
            constant: -Self.cardMargin * 2
        )
        fit.priority = Self.fitPriority
        fit.isActive = true

        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 8
            ),
            backButton.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 8
            ),
            // Below Back even when it's hidden, so the card doesn't shift on the first page.
            cardArea.topAnchor.constraint(
                equalTo: backButton.bottomAnchor,
                constant: 8
            ),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateKeyboardInset()
        countdown.pose = OnboardingCountdownView.pose(
            locksLandscape: PlayfieldTuning.current.prefersLandscape
                && !UIInterfaceOrientationMask.followsDevice,
            size: view.bounds.size
        )
    }

    /// Lets the card scroll out from under the keyboard instead of moving the layout.
    /// Runs on every keyboard change, since `keyboardLayoutGuide` relayouts the view.
    private func updateKeyboardInset() {
        guard let scroll = cardScroll else { return }
        let scrollFrame = scroll.convert(scroll.bounds, to: view)
        let inset = max(
            0,
            scrollFrame.maxY - view.keyboardLayoutGuide.layoutFrame.minY
        )
        guard inset != keyboardInset else { return }
        keyboardInset = inset
        scroll.contentInset.bottom = inset
        scroll.verticalScrollIndicatorInsets.bottom = inset

        let maxOffset = max(
            0,
            scroll.contentSize.height + inset - scroll.bounds.height
        )
        if scroll.contentOffset.y > maxOffset {
            scroll.contentOffset.y = maxOffset
        }
        // Only when the keyboard appears or resizes, so it doesn't fight the owner's scrolling.
        if inset > 0, nameField.isFirstResponder {
            let field = nameField.convert(nameField.bounds, to: scroll).insetBy(
                dx: 0,
                dy: -12
            )
            scroll.scrollRectToVisible(field, animated: false)
        }
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
            text.bottomAnchor.constraint(
                lessThanOrEqualTo: textArea.bottomAnchor
            ),
            text.leadingAnchor.constraint(equalTo: textArea.leadingAnchor),
            text.trailingAnchor.constraint(equalTo: textArea.trailingAnchor),
        ])
    }

    private func makeTextStack(title: UILabel, body: UILabel) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [title, body])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func showCatArt(_ face: CatFace) {
        for art in artRow.arrangedSubviews { art.removeFromSuperview() }
        artRow.addArrangedSubview(
            makeArtImage(
                UIImage(named: face.imageName),
                side: Self.artSide * 1.4
            )
        )
        artRow.isHidden = false
    }

    private func bounceCatArt() {
        guard !UIAccessibility.isReduceMotionEnabled,
            let art = artRow.arrangedSubviews.first
        else { return }
        art.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        UIView.animate(
            withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.45,
            initialSpringVelocity: 0.8, options: [.allowUserInteraction]
        ) {
            art.transform = .identity
        }
    }

    /// `side` is the preferred size; the art shrinks below it when the card needs the room.
    private func makeArtImage(_ image: UIImage?, side: CGFloat) -> UIImageView {
        let picture = UIImageView(image: image)
        picture.contentMode = .scaleAspectFit
        // The SVG's own size mustn't stop the art from shrinking.
        picture.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
        picture.setContentCompressionResistancePriority(
            .defaultLow,
            for: .vertical
        )
        let preferred = picture.heightAnchor.constraint(equalToConstant: side)
        preferred.priority = Self.artPriority
        NSLayoutConstraint.activate([
            preferred,
            picture.heightAnchor.constraint(lessThanOrEqualToConstant: side),
            picture.widthAnchor.constraint(equalTo: picture.heightAnchor),
        ])
        return picture
    }

    private func showCatFields() {
        guard catFields.superview == nil else { return }
        cardStack.addArrangedSubview(catFields)
        catFields.widthAnchor.constraint(equalTo: cardStack.widthAnchor)
            .isActive = true
    }

    /// Slides the card's content in the direction of travel; the first page appears without animation.
    private func transitionCard(to index: Int, _ update: @escaping () -> Void) {
        let previous = shownIndex
        shownIndex = index
        guard let previous, previous != index else {
            update()
            return
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard !UIAccessibility.isReduceMotionEnabled else {
            UIView.transition(
                with: card, duration: 0.25, options: .transitionCrossDissolve,
                animations: update)
            return
        }
        let isRightToLeft = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let forward: CGFloat = index > previous ? 1 : -1
        let shift = 60 * forward * (isRightToLeft ? -1 : 1)
        UIView.animate(withDuration: 0.14, delay: 0, options: [.curveEaseIn]) {
            self.cardStack.alpha = 0
            self.cardStack.transform = CGAffineTransform(translationX: -shift, y: 0)
        } completion: { _ in
            update()
            self.cardStack.transform = CGAffineTransform(translationX: shift, y: 0)
            UIView.animate(
                withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5, options: [.allowUserInteraction]
            ) {
                self.cardStack.alpha = 1
                self.cardStack.transform = .identity
            }
        }
    }

    private func showProgress(_ progress: OnboardingProgress) {
        self.progress = progress
        pageDots.numberOfPages = progress.count
        pageDots.currentPage = progress.index
        pageDots.accessibilityValue = progress.stepLabel
        nextButton.configuration?.title = progress.nextTitle
        backButton.alpha = progress.canGoBack ? 1 : 0
        backButton.isEnabled = progress.canGoBack
        backButton.accessibilityElementsHidden = !progress.canGoBack
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
    }

    // MARK: Actions
    @objc private func nextTapped() {
        presenter?.didTapNext()
    }

    @objc private func backTapped() {
        view.endEditing(true)
        presenter?.didTapBack()
    }

    @objc private func swiped(_ swipe: UISwipeGestureRecognizer) {
        let isRightToLeft =
            view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let forward: UISwipeGestureRecognizer.Direction =
            isRightToLeft ? .right : .left
        if swipe.direction == forward {
            goForward()
        } else {
            goBack()
        }
    }

    /// Moves to the next page; the cat step only finishes from its button, never from a swipe.
    @discardableResult
    private func goForward() -> Bool {
        guard progress?.canSwipeForward == true else { return false }
        presenter?.didTapNext()
        return true
    }

    @discardableResult
    private func goBack() -> Bool {
        guard backButton.isEnabled else { return false }
        backTapped()
        return true
    }

    @objc private func nameChanged() {
        presenter?.didChangeCatName(nameField.text ?? "")
    }

    /// Skipping needs a deliberate hold, like leaving a game; a plain tap only shows a hint.
    private func installHoldToSkip() {
        skipButton.addHoldToConfirm(self, action: #selector(skipHeld(_:)))
        skipButton.addTarget(self, action: #selector(showSkipHint), for: .touchUpInside)
    }

    @objc private func showSkipHint() {
        showHoldHint(skipHint, above: pageDots.topAnchor)
    }

    @objc private func skipHeld(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        presenter?.didTapSkip()
    }

    // MARK: OnboardingViewProtocol
    func showStaticText(_ text: OnboardingStaticText) {
        skipHint = text.skipHint
        skipButton.configuration?.title = text.skipTitle
        skipButton.accessibilityHint = text.skipHint
        // VoiceOver's double-tap is a plain tap, so offer the skip directly too.
        skipButton.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: text.skipAction) { [weak self] _ in
                self?.presenter?.didTapSkip()
                return true
            }
        ]
        holdPractice.prompt = text.holdPrompt
        countdown.accessibilityLabel = text.countdownDescription
    }

    func reserveSpace(for texts: [OnboardingText]) {
        for text in texts {
            let title = Self.makeLabel(size: 28)
            let body = Self.makeLabel(size: 18, weight: .semibold)
            title.text = text.title
            body.text = text.body
            let ghost = makeTextStack(title: title, body: body)
            ghost.alpha = 0
            ghost.isUserInteractionEnabled = false
            ghost.accessibilityElementsHidden = true
            textArea.addSubview(ghost)
            // Optional, so the cat step's shorter text can give the space back on short screens.
            let reserve = ghost.bottomAnchor.constraint(
                lessThanOrEqualTo: textArea.bottomAnchor
            )
            reserve.priority = Self.reservedTextPriority
            NSLayoutConstraint.activate([
                ghost.topAnchor.constraint(equalTo: textArea.topAnchor),
                reserve,
                ghost.leadingAnchor.constraint(equalTo: textArea.leadingAnchor),
                ghost.trailingAnchor.constraint(
                    equalTo: textArea.trailingAnchor
                ),
            ])
        }
    }

    func showPage(_ page: OnboardingPage, progress: OnboardingProgress) {
        stopInteractions()
        interaction = page.interaction
        if page.interaction == .holdToLeave { holdPractice.reset() }
        transitionCard(to: progress.index) {
            self.showPractice(page.interaction)
            self.titleLabel.text = page.title
            self.bodyLabel.text = page.body
            self.catFields.removeFromSuperview()
        }
        showProgress(progress)
        startInteraction()
    }

    func showPracticeFeedback(_ text: OnboardingText, celebrates: Bool) {
        UIView.transition(
            with: textArea, duration: 0.2, options: .transitionCrossDissolve
        ) {
            self.titleLabel.text = text.title
            self.bodyLabel.text = text.body
        }
        if celebrates { bounce(nextButton) }
        UIAccessibility.post(
            notification: .announcement, argument: "\(text.title) \(text.body)")
    }

    func showCatSetup(_ setup: OnboardingCatSetup, progress: OnboardingProgress) {
        stopInteractions()
        interaction = nil
        facePicker.select(setup.face)
        transitionCard(to: progress.index) {
            self.showPractice(nil)
            self.showCatArt(setup.face)
            self.titleLabel.text = setup.title
            self.bodyLabel.text = setup.body
            self.showCatFields()
        }
        showProgress(progress)
    }

    func updateCatSetupTitle(_ title: String) {
        guard titleLabel.text != title else { return }
        titleLabel.text = title
    }

    func showNameRequired(announcement: String) {
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.values = [0, -8, 8, -5, 5, 0]
        shake.duration = 0.3
        nameField.layer.add(shake, forKey: "shake")
        nameField.becomeFirstResponder()
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    func showFinishCelebration(completion: @escaping () -> Void) {
        view.endEditing(true)
        view.isUserInteractionEnabled = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        guard !UIAccessibility.isReduceMotionEnabled else {
            completion()
            return
        }
        burstPawPrints(from: nextButton.convert(nextButton.bounds, to: view))
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            completion()
        }
    }

    // MARK: Accessibility
    /// VoiceOver's three-finger swipe pages through the steps too.
    override func accessibilityScroll(
        _ direction: UIAccessibilityScrollDirection
    ) -> Bool {
        switch direction {
        case .left, .next: return goForward()
        case .right, .previous: return goBack()
        default: return false
        }
    }

    // MARK: UIGestureRecognizerDelegate
    /// Lets the swipes work alongside the card's vertical scroll view when the card is taller than the screen.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer:
            UIGestureRecognizer
    ) -> Bool {
        true
    }

    /// Drags on the practice field are catches, not page swipes.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard gestureRecognizer is UISwipeGestureRecognizer, !playfield.isHidden else {
            return true
        }
        return !playfield.bounds.contains(touch.location(in: playfield))
    }

    // MARK: UITextFieldDelegate
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
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
