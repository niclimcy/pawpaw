//
//  GameViewController.swift
//  pawpaw
//

import UIKit

final class GameViewController: UIViewController, GameViewProtocol {
    var presenter: GamePresenterProtocol?

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
        label.text = "⏱ \(GameInteractor.roundDuration)"
        return label
    }()

    let resultOverlay = UIView()
    let resultTitleLabel = UILabel()
    let resultDetailsLabel = UILabel()

    private var hasStarted = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        installWoodBackground()
        setupGameArea()
        setupHUD()
        setupResultOverlay()

        gameArea.onTapTarget = { [weak self] id in self?.presenter?.didTapTarget(id: id) }
        gameArea.onExpire = { [weak self] id in self?.presenter?.didExpireTarget(id: id) }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start once layout is final so targets map to the real play area size.
        guard !hasStarted else { return }
        hasStarted = true
        presenter?.viewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            presenter?.viewWillDisappear()
        }
    }

    // MARK: Actions
    @objc func homeTapped() {
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
        UIView.animate(withDuration: 0.25) { self.resultOverlay.alpha = 1 }
    }

    func hideResult() {
        resultOverlay.isHidden = true
    }
}

#Preview {
    GameRouter.createModule()
}
