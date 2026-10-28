//
//  GameViewController.swift
//  pawpaw
//

import UIKit

final class GameViewController: UIViewController, GameViewProtocol {
    var presenter: GamePresenterProtocol?
    /// The playfield background, chosen on the Home screen.
    var theme: PlayfieldTheme = .wood

    let gameArea = GameAreaView()

    let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.roundedFont(size: 24)
        label.textColor = Theme.text
        label.text = "Score: 0"
        return label
    }()

    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.roundedFont(size: 24)
        label.textColor = Theme.text
        label.textAlignment = .right
        label.text = "⏱"
        return label
    }()

    let resultOverlay = UIView()
    let resultTitleLabel = UILabel()
    let resultDetailsLabel = UILabel()

    private var hasStarted = false
    /// Whether the result card is up, so coming back from the background doesn't keep the screen awake.
    private var isShowingResult = false
    /// The navigation controller's swipe-back gestures, switched off while playing and restored on the way out.
    private var disabledPopGestures: [UIGestureRecognizer] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.baseColor
        installBackground(theme: theme)
        gameArea.theme = theme
        setupGameArea()
        setupHUD()
        setupResultOverlay()

        gameArea.onTapTarget = { [weak self] id in self?.presenter?.didTapTarget(id: id) }
        gameArea.onExpire = { [weak self] id in self?.presenter?.didExpireTarget(id: id) }
        gameArea.onDiscard = { [weak self] id in self?.presenter?.didDiscardTarget(id: id) }
        gameArea.onMiss = { [weak self] in self?.presenter?.didMissTap() }

        // A call, Control Center or the app switcher pauses the round so it doesn't run on unseen.
        let center = NotificationCenter.default
        center.addObserver(
            self, selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableSwipeBack()
        // Start once layout is final so targets map to the real play area size.
        guard !hasStarted else { return }
        hasStarted = true
        presenter?.viewDidBecomeReady()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // A cat won't touch the screen to keep it awake, so stop it dimming or locking mid-round.
        setScreenAwake(true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setScreenAwake(false)
        restoreSwipeBack()
        if isMovingFromParent || isBeingDismissed {
            presenter?.viewWillDisappear()
        }
    }

    /// Keeps the screen on while critters are running. The result card lets it sleep again.
    private func setScreenAwake(_ awake: Bool) {
        UIApplication.shared.isIdleTimerDisabled = awake
    }

    /// A paw sweeping across the screen must never leave the game, so the edge swipe and the iOS 26
    /// full-screen swipe back are off while playing. The hold on the home button is the only way out.
    private func disableSwipeBack() {
        guard disabledPopGestures.isEmpty, let navigation = navigationController else { return }
        var gestures = [navigation.interactivePopGestureRecognizer]
        if #available(iOS 26.0, *) {
            gestures.append(navigation.interactiveContentPopGestureRecognizer)
        }
        disabledPopGestures = gestures.compactMap { $0 }.filter(\.isEnabled)
        disabledPopGestures.forEach { $0.isEnabled = false }
    }

    private func restoreSwipeBack() {
        disabledPopGestures.forEach { $0.isEnabled = true }
        disabledPopGestures = []
    }

    // MARK: App lifecycle
    @objc private func appWillResignActive() {
        presenter?.appWillResignActive()
    }

    @objc private func appDidBecomeActive() {
        // Only resume when this screen is the one showing.
        guard hasStarted, viewIfLoaded?.window != nil else { return }
        presenter?.appDidBecomeActive()
    }

    // MARK: Actions
    func leaveGame() {
        presenter?.didTapHome()
    }

    @objc func playAgainTapped() {
        presenter?.didTapPlayAgain()
    }

    // MARK: GameViewProtocol
    func showScore(_ text: String) {
        scoreLabel.text = text
    }

    func showTime(_ text: String) {
        timeLabel.text = text
    }

    func showTarget(_ target: GameTarget) {
        gameArea.add(target)
    }

    func showHidingSpots(_ points: [CGPoint]) {
        gameArea.showHidingSpots(at: points)
    }

    func showCatch(targetID: UUID, points: Int) {
        gameArea.caught(id: targetID, points: points)
    }

    func clearTargets() {
        gameArea.removeAllTargets()
    }

    func showResult(title: String, details: String) {
        resultTitleLabel.text = title
        resultDetailsLabel.text = details
        resultOverlay.alpha = 0
        resultOverlay.isHidden = false
        isShowingResult = true
        UIView.animate(withDuration: 0.25) { self.resultOverlay.alpha = 1 }
        // The round is over: if nobody comes back, the device can sleep as usual.
        setScreenAwake(false)
        // VoiceOver moves to the result and can't wander onto the playfield behind it.
        UIAccessibility.post(notification: .screenChanged, argument: resultTitleLabel)
    }

    func hideResult() {
        resultOverlay.isHidden = true
        isShowingResult = false
        setScreenAwake(true)
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }

    func showPaused() {
        setScreenAwake(false)
    }

    func showResumed() {
        setScreenAwake(!isShowingResult)
    }
}

@available(iOS 17.0, *)
#Preview {
    GameRouter.createModule(mode: .standard)
}
