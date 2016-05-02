//
//  GameViewController.swift
//  My2048
//
//  Created by JMacMini on 16/4/29.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import UIKit

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

    var switcher: UISwitch!
    var autoPlay: Bool = false

    var scoreView: ScoreView!

    var gameView: GameView!
    var gameLogic: GameLogicModel!
    
    var gameDimension: Int = 6

    var gameOver: Bool = false
    
    // MARK: - 初始化
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil);
        view.backgroundColor = UIColor.whiteColor()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

        gameView = GameView(dimension: gameDimension, gap: 5, corner: 6)
        gameView.frame = CGRectMake(0, 0, 300, 300)
        gameView.center = view.center
        view.addSubview(gameView)

        scoreView = ScoreView()
        scoreView.frame = CGRectMake(0, 0, 100, 40)
        scoreView.center = CGPointMake(gameView.center.x, gameView.frame.origin.y - scoreView.frame.size.height / 2 - 10)
        view.addSubview(scoreView)

        switcher = UISwitch()
        switcher.on = false
        view.addSubview(switcher)
        switcher.addTarget(self, action: #selector(GameViewController.switcherChange(_:)), forControlEvents: .ValueChanged)
        
        setupGame()
        
//        testCommond()
//        startAutoPlay()

    }

    func switcherChange(switcher: UISwitch) {
        autoPlay = switcher.on
        if switcher.on {
            startAutoPlay()
        }
    }

    // MARK: - 游戏逻辑
    func goonGame() {
        let state = gameLogic.checkGameState()
        switch state {
        case .Win:
            gameOver4Win()
        case .Lose:
            gameOver4Lose()
        case .Normal:
            gameLogic.insertTileIntoBoardRandom()
        }
    }

    func resetGame() {
        gameView.resetGameView()
        gameLogic.resetGameLogic()
        gameLogic.insertTileIntoBoardRandom()
        gameLogic.insertTileIntoBoardRandom()
        gameLogic.score = 0
        gameOver = false
    }

    func gameOver4Win() {
        let alertController = UIAlertController(title: "you win", message: nil, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Restart", style: .Default) { (ac: UIAlertAction) in
            self.resetGame()
        }
        alertController.addAction(action)
        presentViewController(alertController, animated: true, completion: nil)
        gameOver = true
    }

    func gameOver4Lose() {
        let alertController = UIAlertController(title: "you lose", message: nil, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Restart", style: .Default) { (ac: UIAlertAction) in
            self.resetGame()
        }
        alertController.addAction(action)
        presentViewController(alertController, animated: true, completion: nil)
        gameOver = true
    }

    func setupGame() {
        gameLogic = GameLogicModel(dimension: gameDimension, delegate: self, maxScore: 2048)
        gameLogic.insertTileIntoBoardRandom()
        gameLogic.insertTileIntoBoardRandom()
    }

    func rightUp(reco: UISwipeGestureRecognizer?) {
        print("RightUp");
        gameLogic.appendCommond(MoveCommond(direction: .RightUp, completion: { (flag) in
            self.goonGame()
        }))
    }
    func leftDown(reco: UISwipeGestureRecognizer?) {
        print("LeftDown");
        gameLogic.appendCommond(MoveCommond(direction: .LeftDown, completion: { (flag) in
            self.goonGame()
        }))
    }
    func leftUp(reco: UISwipeGestureRecognizer?) {
        print("LeftUp");
        gameLogic.appendCommond(MoveCommond(direction: .LeftUp, completion: { (flag) in
            self.goonGame()
        }))
    }
    func rightDown(reco: UISwipeGestureRecognizer?) {
        print("RightDown");
        gameLogic.appendCommond(MoveCommond(direction: .RightDown, completion: { (flag) in
            self.goonGame()
        }))
    }

    func up(reco: UISwipeGestureRecognizer?) {
        print("up");
        gameLogic.appendCommond(MoveCommond(direction: .Up, completion: { (flag) in
            self.goonGame()
        }))
    }
    func down(reco: UISwipeGestureRecognizer?) {
        print("down");
        gameLogic.appendCommond(MoveCommond(direction: .Down, completion: { (flag) in
            self.goonGame()
        }))
    }
    func left(reco: UISwipeGestureRecognizer?) {
        print("left");
        gameLogic.appendCommond(MoveCommond(direction: .Left, completion: { (flag) in
            self.goonGame()
        }))
    }
    func right(reco: UISwipeGestureRecognizer?) {
        print("right");
        gameLogic.appendCommond(MoveCommond(direction: .Right, completion: { (flag) in
            self.goonGame()
        }))
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }


    func startAutoPlay() {
        if gameOver {return}
        let dirs = [MoveDirection.Down,
                    MoveDirection.Up,
                    MoveDirection.Left,
                    MoveDirection.Right,
                    MoveDirection.RightUp,
                    MoveDirection.RightDown,
                    MoveDirection.LeftUp,
                    MoveDirection.LeftDown
        ]
        let idx = Int(arc4random_uniform(UInt32(dirs.count)))
        gameLogic.appendCommond(MoveCommond(direction: dirs[idx], completion: { (flag) in
            self.goonGame()
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
        return !autoPlay
    }
}

