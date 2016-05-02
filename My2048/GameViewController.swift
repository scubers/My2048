//
//  GameViewController.swift
//  My2048
//
//  Created by JMacMini on 16/4/29.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import UIKit

let MaxScore: Int = 2048

class ScoreView : UIView {
    var label: UILabel!
    var score: Int = 0 {
        didSet {
            label.text = "\(score)"
        }
    }
    required init?(coder aDecoder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.blackColor()
        layer.masksToBounds = true
        layer.cornerRadius = 6;
        setupSubview()
    }

    func setupSubview() {
        label = UILabel()
        self.addSubview(label)
        label.textAlignment = .Center
        label.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
        label.textColor = UIColor.whiteColor()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
}

// MARK: - GameViewController
class GameViewController: UIViewController {

    // MARK: - 设置控件

    @IBOutlet weak var autoSwitch: UISwitch!
    @IBOutlet weak var cornerSwitch: UISwitch!
    @IBOutlet weak var dimensionField: UITextField!
    @IBOutlet weak var winConditionField: UITextField!

    @IBAction func resetClick(sender: AnyObject) {
        let num = Int(dimensionField.text!)!
        guard num > 2 else {
            let alert = UIAlertController(title: nil, message: "不能低于4维", preferredStyle: .Alert)
            let action = UIAlertAction(title: "确定", style: .Default, handler: nil)
            alert.addAction(action)
            presentViewController(alert, animated: true, completion: nil)
            return
        }

        let winCon = Int(winConditionField.text!)!
        guard winCon >= 128 else {
            let alert = UIAlertController(title: nil, message: "不能低于128分", preferredStyle: .Alert)
            let action = UIAlertAction(title: "确定", style: .Default, handler: nil)
            alert.addAction(action)
            presentViewController(alert, animated: true, completion: nil)
            return
        }

        self.becomeFirstResponder()

        let alert = UIAlertController(title: nil, message: "确定要重置吗？", preferredStyle: .Alert)
        let action = UIAlertAction(title: "确定", style: .Default) { [weak self] (ac) in
            self?.gameDimension = num
            self?.winCondition = winCon
            self?.resetGame()
        }
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: - 设置参数
    var winCondition: Int = MaxScore
    var gameDimension: Int = 6
    var gameOver: Bool = false
    var autoPlay: Bool = false
    var enableCornerDirection: Bool = false {
        didSet {
            gameLogic.enableCornerDirection = enableCornerDirection
        }
    }

    // MARK: - 界面
    var scoreView: ScoreView!
    var gameView: GameView!

    // MARK: - 逻辑
    var gameLogic: GameLogicModel!


    // MARK: - 初始化
    convenience init(enableCornerDirection flag: Bool = false, dimension d: Int = 4) {
        self.init(nibName: nil, bundle: nil);
        enableCornerDirection = flag
        gameDimension = d
    }

    // Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupGesture()
        setupGame()

    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        autoSwitch.on = autoPlay
        cornerSwitch.on = enableCornerDirection
        dimensionField.text = "\(gameDimension)"
        winConditionField.text = "\(winCondition)"
    }

    func setupUI() {

        print(view.frame)

        // 游戏界面
        let width = UIScreen.mainScreen().bounds.size.width - 10
        let cx = CGRectGetMidX(UIScreen.mainScreen().bounds)
        let cy = CGRectGetMidY(UIScreen.mainScreen().bounds)
        gameView = GameView(dimension: gameDimension, gap: 5, corner: 6)
        gameView?.frame = CGRectMake(0, 0, width, width)
        gameView?.center = CGPointMake(cx, cy)
        view.addSubview(gameView!)

        // 分数view
        scoreView = ScoreView()
        scoreView.frame = CGRectMake(0, 0, 100, 40)
        scoreView.center = CGPointMake(gameView!.center.x, CGRectGetMaxY(gameView!.frame) + scoreView.frame.size.height / 2 + 10)
        view.addSubview(scoreView)

        autoSwitch.addTarget(self, action: #selector(GameViewController.autoPlayDidChange(_:)), forControlEvents: .ValueChanged)
        cornerSwitch.addTarget(self, action: #selector(GameViewController.enableCornerDirectionDidChange(_:)), forControlEvents: .ValueChanged)
    }

    func setupGesture() {

        // 初始化手势
        let up = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.up(_:)))
        up.direction = .Up
        up.numberOfTouchesRequired = 1;
        view.addGestureRecognizer(up)

        let down = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.down(_:)))
        down.direction = .Down
        down.numberOfTouchesRequired = 1;
        view.addGestureRecognizer(down)

        let left = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.left(_:)))
        left.direction = .Left
        left.numberOfTouchesRequired = 1;
        view.addGestureRecognizer(left)

        let right = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.right(_:)))
        right.direction = .Right
        right.numberOfTouchesRequired = 1;
        view.addGestureRecognizer(right)

        up.delegate = self
        down.delegate = self
        left.delegate = self
        right.delegate = self

        let pan = UIPanGestureRecognizer(target: self, action: #selector(GameViewController.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        view.addGestureRecognizer(pan)

    }

    func autoPlayDidChange(switcher: UISwitch) {
        autoPlay = switcher.on
        if switcher.on {
            startAutoPlay()
        }
    }

    func enableCornerDirectionDidChange(switcher: UISwitch) {
        enableCornerDirection = switcher.on
    }

    // MARK: - 游戏逻辑
    func goonGame(hasChange: Bool) {
        if hasChange {
            gameLogic.insertTileIntoBoardRandom()
        }
        let state = gameLogic.checkGameState()
        switch state {
        case .Win:
            gameOver4Win()
        case .Lose:
            gameOver4Lose()
        default:
            gameOver = false
        }
    }

    func resetGame() {
//        dimensionField.resignFirstResponder()
//        winConditionField.resignFirstResponder()
        autoSwitch.on = false
        autoPlayDidChange(autoSwitch)
        gameOver = false
        gameView.dimension = gameDimension
        gameView.resetGameView()
        setupGame()
        scoreView.score = gameLogic.score
    }

    func gameOver4Win() {
        let alertController = UIAlertController(title: "you win", message: nil, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Restart", style: .Default) { (ac: UIAlertAction) in}
        alertController.addAction(action)
        presentViewController(alertController, animated: true, completion: nil)
        gameOver = true
    }

    func gameOver4Lose() {
        let alertController = UIAlertController(title: "you lose", message: nil, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Restart", style: .Default) { (ac: UIAlertAction) in}
        alertController.addAction(action)
        presentViewController(alertController, animated: true, completion: nil)
        gameOver = true
    }

    func setupGame() {
        gameLogic = GameLogicModel(dimension: gameDimension, enableCornerDirection: enableCornerDirection, delegate: self, maxScore: winCondition)
        gameLogic.insertTileIntoBoardRandom()
        gameLogic.insertTileIntoBoardRandom()
    }

    // MARK: - 对角方向操作
    var startPoint: CGPoint?
    var endPoint: CGPoint?
    func handlePan(reco: UIPanGestureRecognizer) {
        let state = reco.state

        switch state {
        case .Began:
            startPoint = reco.locationInView(view)
        case .Ended,.Cancelled:
            endPoint = reco.locationInView(view)
            let vector = CGVectorMake(endPoint!.x - startPoint!.x, endPoint!.y - startPoint!.y)
            let r = radianWithVector(vector)
            let direction = directionWithRadian(r)
            gameLogic.appendCommond(MoveCommond(direction: direction, completion: { (flag) in
                self.goonGame(flag)
            }))
            startPoint = nil
            endPoint = nil
        default: break
        }
    }

    func radianWithVector(vector: CGVector) -> Double {
        let x = Double(vector.dx)
        let y = Double(vector.dy)
        var r: Double = 0.0
        let l = sqrt(x * x + y * y)
        if x > 0 {
            r = asin(Double(y) / l)
            while r < 0 {
                r += 2 * M_PI
            }
        } else {
            r = M_PI - asin(Double(y) / l)
        }
        return r
    }

    func directionWithRadian(radian: Double) -> MoveDirection {
        let radio = radian / M_PI
        if radio > (15/8.0) || radio < (1/8.0) {
            // right
            return .Right
        }
        if radio > (1/8.0) && radio < (3/8.0) {
            // rightDown
            return .RightDown
        }
        if radio > (3/8.0) && radio < (5/8.0) {
            // down
            return .Down
        }
        if radio > (5/8.0) && radio < (7/8.0) {
            // leftDown
            return .LeftDown
        }
        if radio > (7/8.0) && radio < (9/8.0) {
            // left
            return .Left
        }
        if radio > (9/8.0) && radio < (11/8.0) {
            // leftUp
            return .LeftUp
        }
        if radio > (11/8.0) && radio < (13/8.0) {
            // up
            return .Up
        }
        if radio > (13/8.0) && radio < (15/8.0) {
            // RightUp
            return .RightUp
        }
        return .Right
    }

    // MARK: - 上下左右
    func up(reco: UISwipeGestureRecognizer?) {
        print("up");
        gameLogic.appendCommond(MoveCommond(direction: .Up, completion: { (flag) in
            self.goonGame(flag)
        }))
    }
    func down(reco: UISwipeGestureRecognizer?) {
        print("down");
        gameLogic.appendCommond(MoveCommond(direction: .Down, completion: { (flag) in
            self.goonGame(flag)
        }))
    }
    func left(reco: UISwipeGestureRecognizer?) {
        print("left");
        gameLogic.appendCommond(MoveCommond(direction: .Left, completion: { (flag) in
            self.goonGame(flag)
        }))
    }
    func right(reco: UISwipeGestureRecognizer?) {
        print("right");
        gameLogic.appendCommond(MoveCommond(direction: .Right, completion: { (flag) in
            self.goonGame(flag)
        }))
    }

    // MARK: - Controller 方法

    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }


    func startAutoPlay() {
        if gameOver {return}
        var dirs = [MoveDirection.Down,
                    MoveDirection.Up,
                    MoveDirection.Left,
                    MoveDirection.Right,
        ]
        if enableCornerDirection {
            dirs.appendContentsOf([MoveDirection.RightUp,
                                    MoveDirection.RightDown,
                                    MoveDirection.LeftUp,
                                    MoveDirection.LeftDown])
        }
        let idx = Int(arc4random_uniform(UInt32(dirs.count)))
        gameLogic.appendCommond(MoveCommond(direction: dirs[idx], completion: { (flag) in
            self.goonGame(flag)
        }))
        if !gameOver && autoPlay {
            NSTimer.scheduledTimerWithTimeInterval(0.15, target: self, selector: #selector(GameViewController.startAutoPlay), userInfo: nil, repeats: false)
        }
    }

    // MARK: -  测试方法
    var queue: [dispatch_block_t] = [dispatch_block_t]()
    var timer: NSTimer?
    func testCommond() {

        gameLogic.insertTileIntoBoardRandom()
        gameLogic.insertTileIntoBoardRandom()

        if queue.count > 0 {
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(GameViewController.executeCommond), userInfo: nil, repeats: true)
        }
    }
    func executeCommond() {
        queue.removeFirst()()
        if queue.count == 0 {
            timer?.invalidate()
        }
    }
}

// MARK: - GameLogicModelProtol
extension GameViewController : GameLogicModelProtol {
    func didInsertTileAt(position: (Int, Int), value: Int) {
        let (col, row) = position
        let idx = NSIndexPath(forRow: row, inSection: col)
        self.gameView.insertTileAtIndexPath(idx, value: value)
    }

    func moveOneFrom(from: (Int, Int), to: (Int, Int), value: Int, mix: Bool, complete: ((Bool) -> ())?) {
        gameView.moveOneTile(from: NSIndexPath(forRow: from.1, inSection: from.0), to: NSIndexPath(forRow: to.1, inSection: to.0), value: value, mixed: mix, complete: complete)

    }

    func moveTowFrom(from1: (Int, Int), from2: (Int, Int), to: (Int, Int), value: Int, complete: ((Bool) -> ())?) {
        gameView.moveTwoTile(first: NSIndexPath(forRow: from1.1, inSection: from1.0), second: NSIndexPath(forRow: from2.1, inSection: from2.0), to: NSIndexPath(forRow: to.1, inSection: to.0), value: value, complete: complete)
    }

    func scoreDidChange(score: Int) {
        scoreView.score = score
    }
}

// MARK: - UIGestureRecognizerDelegate
extension GameViewController : UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKindOfClass(UIPanGestureRecognizer.self) {
            return enableCornerDirection
        } else if gestureRecognizer.isKindOfClass(UISwipeGestureRecognizer.self) {
            return !autoPlay
        }
        return false
    }
}

