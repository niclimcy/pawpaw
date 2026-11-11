//
//  GameViewController.swift
//  pawpaw
//

import SpriteKit
import UIKit

final class GameViewController: UIViewController, GameViewProtocol {
    var presenter: GamePresenterProtocol?
    var theme: PlayfieldTheme = .wood
    var tuning: PlayfieldTuning = .standard

    /// Fills the screen, under the HUD too, so critters leave by the real screen edge.
    let gameArea = SKView()
    let scene = GameScene(size: CGSize(width: 1, height: 1))
    /// The part of `gameArea` below the HUD.
    let playfieldGuide = UILayoutGuide()

    let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.roundedFont(size: 24)
        label.textColor = Theme.text
        label.text = "Score: 0"
        return label
    }()

    private static let timerSymbol = "timer"

    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.roundedFont(size: 24)
        label.textColor = Theme.text
        label.textAlignment = .right
        // Empty until the round starts; `showTime` adds the timer icon.
        return label
    }()

    /// Only the card takes touches; the rest of the screen stays a play area for the lure.
    let resultOverlay = PassthroughView()
    let resultTitleLabel = UILabel()
    let resultDetailsLabel = UILabel()
    /// Cover for the lure between rounds.
    weak var resultCard: UIView?
    /// Bumped to invalidate an already-scheduled lure start.
    var lureGeneration = 0
    var lureIdleWork: DispatchWorkItem?

    weak var hudHomeButton: UIButton?
    /// Kept while backgrounded so the countdown can restart.
    var pendingCountdown: PendingCountdown?
    /// Bumped to invalidate already-scheduled countdown steps.
    var countdownGeneration = 0

    private var hasStarted = false
    private(set) var isShowingResult = false
    private var disabledPopGestures: [UIGestureRecognizer] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.baseColor
        installBackground(theme: theme)
        scene.theme = theme
        scene.tuning = tuning
        setupGameArea()
        setupHUD()
        setupResultOverlay()

        scene.onTapTarget = { [weak self] id in self?.presenter?.didTapTarget(id: id) }
        scene.onExpire = { [weak self] id in self?.presenter?.didExpireTarget(id: id) }
        scene.onDiscard = { [weak self] id in self?.presenter?.didDiscardTarget(id: id) }
        scene.onMiss = { [weak self] in self?.presenter?.didMissTap() }
        setupLure()

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePlayfieldInset()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableSwipeBack()
        // Start once layout is final so targets map to the real play area.
        guard !hasStarted else { return }
        hasStarted = true
        presenter?.viewDidBecomeReady()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setScreenAwake(true)
        rotateToSupportedOrientation()
    }

    // MARK: Orientation
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        tuning.prefersLandscape ? .landscape : super.supportedInterfaceOrientations
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        tuning.prefersLandscape
            ? .landscapeRight : super.preferredInterfaceOrientationForPresentation
    }

    /// Mid-push, this view isn't in the window yet.
    private var windowScene: UIWindowScene? {
        (view.window ?? navigationController?.view.window)?.windowScene
    }

    private func rotateToSupportedOrientation() {
        guard tuning.prefersLandscape else { return }
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
            navigationController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    /// Home is portrait-only on iPhone, so re-checking once it's on top turns the screen back.
    private func releaseOrientationLock() {
        guard tuning.prefersLandscape, let navigation = navigationController else { return }
        let lockedScene = windowScene
        let release: @MainActor @Sendable () -> Void = {
            if #available(iOS 16.0, *) {
                navigation.setNeedsUpdateOfSupportedInterfaceOrientations()
                lockedScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .menus))
            } else {
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { context in
                if !context.isCancelled { release() }
            }
        } else {
            DispatchQueue.main.async(execute: release)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setScreenAwake(false)
        restoreSwipeBack()
        if isMovingFromParent || isBeingDismissed {
            cancelCountdown()
            cancelLure()
            presenter?.viewWillDisappear()
            releaseOrientationLock()
        }
    }

    func setScreenAwake(_ awake: Bool) {
        UIApplication.shared.isIdleTimerDisabled = awake
    }

    /// Paws must never swipe out of the game; the home button hold is the only exit.
    private func disableSwipeBack() {
        guard disabledPopGestures.isEmpty, let navigation = navigationController else { return }
        var gestures = [navigation.interactivePopGestureRecognizer]
        if #available(iOS 26.0, *) {
            gestures.append(navigation.interactiveContentPopGestureRecognizer)
        }
        disabledPopGestures = gestures.compactMap { $0 }.filter(\.isEnabled)
        for gesture in disabledPopGestures { gesture.isEnabled = false }
    }

    private func restoreSwipeBack() {
        for gesture in disabledPopGestures { gesture.isEnabled = true }
        disabledPopGestures = []
    }

    // MARK: App lifecycle
    @objc private func appWillResignActive() {
        interruptCountdown()
        pauseLureIdleTimer()
        presenter?.appWillResignActive()
    }

    @objc private func appDidBecomeActive() {
        guard hasStarted, viewIfLoaded?.window != nil else { return }
        if let pending = pendingCountdown {
            showGetReady(showsExitTip: pending.showsExitTip, completion: pending.completion)
            return
        }
        resumeLureIdleTimer()
        presenter?.appDidBecomeActive()
    }

    // MARK: Actions
    /// A hold, so a paw on the card can't start a round and bypass the after-round setting.
    @objc func playAgainHeld(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        presenter?.didTapPlayAgain()
    }

    @objc func showPlayAgainHint() {
        showHoldHint("Press and hold to play again")
    }

    // MARK: GameViewProtocol
    func showScore(_ text: String) {
        scoreLabel.text = text
    }

    func showTime(_ text: String) {
        timeLabel.attributedText = Theme.symbolText(
            Self.timerSymbol, text, font: timeLabel.font, color: timeLabel.textColor
        )
        timeLabel.accessibilityLabel = "Time: \(text)"
    }

    /// Hides the timer until the next round starts counting down.
    func clearTime() {
        timeLabel.attributedText = nil
        timeLabel.accessibilityLabel = nil
    }

    func showTarget(_ target: GameTarget) {
        scene.add(target)
    }

    func showHidingSpots(_ points: [CGPoint]) {
        scene.showHidingSpots(at: points)
    }

    func showCatch(targetID: UUID, points: Int) {
        scene.caught(id: targetID, points: points)
    }

    func clearTargets() {
        scene.removeAllTargets()
    }

    func showResult(title: String, symbol: String?, details: String) {
        setResultTitle(title, symbol: symbol)
        resultDetailsLabel.text = details
        resultOverlay.alpha = 0
        resultOverlay.isHidden = false
        isShowingResult = true
        UIView.animate(withDuration: 0.25) { self.resultOverlay.alpha = 1 }
        // Stays awake while the lure plays; it sleeps once the lure leaves or is caught for the last time.
        UIAccessibility.post(notification: .screenChanged, argument: resultTitleLabel)
    }

    /// The title, with an SF Symbol after it when given; VoiceOver reads only the text.
    func setResultTitle(_ title: String, symbol: String?) {
        guard let symbol else {
            resultTitleLabel.text = title
            resultTitleLabel.accessibilityLabel = nil
            return
        }
        resultTitleLabel.attributedText = Theme.symbolText(
            symbol, title, font: resultTitleLabel.font, color: resultTitleLabel.textColor,
            trailing: true
        )
        resultTitleLabel.accessibilityLabel = title
    }

    func hideResult() {
        cancelLure()
        resultOverlay.isHidden = true
        isShowingResult = false
        setScreenAwake(true)
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }

    func freezeTargets() {
        scene.freeze()
    }

    func resumeTargets() {
        scene.resume()
    }

    func showPaused() {
        setScreenAwake(false)
    }

    func showResumed() {
        setScreenAwake(!isShowingResult || scene.hasLure)
    }
}

@available(iOS 17.0, *)
#Preview {
    GameRouter.createModule(mode: .standard)
}
