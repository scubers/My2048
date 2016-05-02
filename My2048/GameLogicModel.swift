//
//  GameModel.swift
//  My2048
//
//  Created by JMacMini on 16/4/29.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import Foundation

// MARK: - 瓦片实例
enum TileType {
    case Empty
    case Tile
}

typealias TileColumnAndRow = (Int, Int)
protocol Tile {
    
    var tileType: TileType {get}
    var position: TileColumnAndRow {get set}
    
    init(tileType type: TileType, postion p : TileColumnAndRow)
}

class BaseTile : Tile {
    var tileType: TileType
    var position: TileColumnAndRow
    
    required init(tileType type: TileType, postion p : TileColumnAndRow) {
        tileType = type
        position = p
    }
}

class EmptyTile: BaseTile {
    init(position: TileColumnAndRow) {
        super.init(tileType: .Empty, postion: position)
    }
    required init(tileType type: TileType, postion p: TileColumnAndRow) {
        fatalError("init(tileType:postion:) has not been implemented")
    }
}

class TileObject: BaseTile {
    
    var value: Int = 2
    var prePositionFirst: TileColumnAndRow?
    var prePositionSecond: TileColumnAndRow?
    var mixed: Bool = false
    
    required init(tileType type: TileType, postion p: TileColumnAndRow) {
        fatalError("init(tileType:postion:) has not been implemented")
    }
    
    init(value v: Int, position p: TileColumnAndRow, prePositionFirst pp: TileColumnAndRow? = nil, prePositionSecond ppp: TileColumnAndRow? = nil, mixed mix: Bool = false) {
        super.init(tileType: .Tile, postion: p)
        value = v
        prePositionFirst = pp
        prePositionSecond = ppp
        mixed = mix
    }
    
    func clearOldMessage() {
        prePositionFirst = nil
        prePositionSecond = nil
        mixed = false
    }
}

// MARK: - 移动方向
enum MoveDirection {
    case Up
    case Down
    case Left
    case Right
    case RightUp
    case LeftUp
    case RightDown
    case LeftDown
}

// MARK: - 移动指令
struct MoveCommond {
    let direction: MoveDirection
    var completion: (Bool)->()

    init(direction d: MoveDirection, completion c: (Bool)->()) {
        direction = d
        completion = c
    }
}
// MARK: - 游戏状态
enum GameState {
    case Normal
    case Win
    case Lose
}

// MARK: - 逻辑状态
enum GameLogicState {
    case Default
    case Caculating
}
// MARK: - 逻辑模型代理协议

protocol GameLogicModelProtol : class {
    func didInsertTileAt(position: (Int, Int), value: Int);
    func moveOneFrom(from: (Int, Int), to: (Int, Int), value: Int, mix: Bool, complete: ((Bool)->())?)
    func moveTowFrom(from1: (Int, Int), from2: (Int, Int), to: (Int, Int), value: Int, complete: ((Bool)->())?)
    func scoreDidChange(scroe: Int)
}

// MARK: - 逻辑模型

class GameLogicModel: NSObject {

    private var gameBoard: SquareGameBoard<Tile>!
    private var commondQueue: [MoveCommond] = [MoveCommond]()
    var timer: NSTimer = NSTimer()

    var currentCommond: MoveCommond?

    var logicState: GameLogicState = .Default

    var maxScore: Int = 2048
    var score: Int = 0 {
        didSet {
            delegate.scoreDidChange(score)
        }
    }

    unowned let delegate: GameLogicModelProtol
    
    init(dimension: Int = 4, delegate d: GameLogicModelProtol, maxScore score: Int = 2048) {
        gameBoard = SquareGameBoard(dimension: dimension, initialValue: EmptyTile(position: (0, 0)))
        delegate = d
        maxScore = score
        super.init()
    }
    
    func appendCommond(commond: MoveCommond) {
        commondQueue.append(commond)
        startMove()
//        if !timer.valid {
//            timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: #selector(GameLogicModel.startMove), userInfo: nil, repeats: false)
//        }
    }
    
    // MARK: 添加瓦片操作
    func insertTileIntoBoardRandom() {
        var emptyList = gameBoardEmptyList()
        if emptyList.count == 0 { return }
        let randomIdx = Int(arc4random_uniform(UInt32(emptyList.count)))
        let (c1,r1) = emptyList.removeAtIndex(randomIdx)
        let value = arc4random_uniform(10) == 1 ? 4 : 2;
        gameBoard[c1, r1] = TileObject(value: value, position: (c1, r1))
        // TODO: 通知代理，新增了两个瓦片
        delegate.didInsertTileAt((c1,r1), value: value)
    }

    // MARK: 移动.合并 瓦片操作
    func startMove() {
        if logicState == .Caculating { return }
        logicState = .Caculating

        if commondQueue.count == 0 { return }
        currentCommond = commondQueue.removeFirst()
        performMove(moveCommond: currentCommond!)
//        commond.completion(true)
//        if commondQueue.count > 0 {
//            timer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: #selector(GameLogicModel.startMove), userInfo: nil, repeats: false)
//        }
    }

    func finishMove() {
        assert(logicState != .Default && currentCommond != nil, "Logic state error")
        logicState = .Default

        currentCommond!.completion(true)
        currentCommond = nil

        if commondQueue.count > 0 {
            startMove()
        }
    }

    // MARK: - 移动的逻辑操作
    func performMove(moveCommond mc: MoveCommond) {
        let coordinates: [[TileColumnAndRow]] = breakDownSquareCoordinateBy(mc.direction)

        var needMoveTiles = [TileObject]()
        for i in 0..<coordinates.count {
            let subCoordinates = coordinates[i]
            let tiles = subCoordinates.map({ (col, row) -> Tile in
                return gameBoard[col, row]
            })
            var newGroup = move(tiles)
            for i in 0..<newGroup.count {newGroup[i].position = subCoordinates[i]}
            newGroup = merge(newGroup)
            for i in 0..<newGroup.count {newGroup[i].position = subCoordinates[i]}
            needMoveTiles.appendContentsOf(newGroup)
        }

        for (idx, tile) in needMoveTiles.enumerate() {
            // TODO: 通知代理如何移动 清空数据， 整理棋盘信息
            notifyDelegateWithTile(tile, isLast: idx == needMoveTiles.count - 1)
            // 修改棋盘model信息
            fixGameBoard(tile)
        }
    }

    func caculate(group: [Tile]) -> [TileObject] {
        let newGroup = merge(move(group))
        return newGroup
    }
    
    func move(group: [Tile]) -> [TileObject] {
        var newGroup = [TileObject]()
        for tile in group {
            if let t = tile as? TileObject {
                newGroup.append(t)
                t.prePositionFirst = t.position
            }
        }
        return newGroup
    }
    
    func merge(group: [TileObject]) -> [TileObject] {
        var newGroup = [TileObject]()
        var skip = false
        for i in 0..<group.count {
            if skip {skip = false; continue}
            let current = group[i]
            if i == group.count - 1 {newGroup.append(current);break}
            let next = group[i + 1]
            if current.value == next.value { // 需要合并
                if current.position == current.prePositionFirst! { // 当前的没动
                    let tile = TileObject(value: current.value * 2, position: current.position, prePositionFirst: next.prePositionFirst, mixed: true)
                    newGroup.append(tile)
                } else if (current.position != current.prePositionFirst!) { // 当前的动了
                    let tile = TileObject(value: current.value * 2, position: current.position, prePositionFirst: current.prePositionFirst, prePositionSecond: next.prePositionFirst, mixed: true)
                    newGroup.append(tile)
                }
                score += current.value * 2
                skip = true
            } else {
                newGroup.append(current)
            }
        }
        return newGroup
    }
    
    private func breakDownSquareCoordinateBy(direction: MoveDirection) -> [[TileColumnAndRow]] {
        var list: [[TileColumnAndRow]] = [[TileColumnAndRow]]()

        if direction == .Up ||
            direction == .Down ||
            direction == .Left ||
            direction == .Right
        {
            for i in 0..<gameBoard.dimension {
                var subList: [TileColumnAndRow] = [TileColumnAndRow]()
                for j in 0..<gameBoard.dimension {
                    var pos: TileColumnAndRow = (-1, -1)
                    switch direction {
                    case .Up: pos = (i, j)
                    case .Down: pos = (i, gameBoard.dimension - j - 1)
                    case .Left: pos = (j, i)
                    case .Right: pos = (gameBoard.dimension - j - 1, i)
                    default:
                        break
                    }
                    subList.append(pos)
                }
                list.append(subList)
            }
        } else {
            let d = gameBoard.dimension
            let count = d * 2 - 1
            for i in 0..<count {
                var subList: [TileColumnAndRow] = [TileColumnAndRow]()
                let subCount = (d - 1) - abs(d - 1 - i)
                for j in 0...subCount {
                    var col = 0
                    var row = 0
                    switch direction {
                    case .RightUp: // col-- row++
                        col = min(d - 1, i) - j
                        row = max(i - d + 1, 0) + j
                    case .LeftDown: // col++ row--
                        col = max(i - d + 1, 0) + j
                        row = min(d - 1, i) - j
                    case .LeftUp: // col++ row++
                        col = max(d - i - 1, 0) + j
                        row = max(i - d + 1, 0) + j
                    case .RightDown: // col-- row--
                        col = min(2 * (d - 1) - i, d - 1) - j
                        row = min(d - 1, i) - j
                    default:
                        break
                    }
                    subList.append((col, row))
                }
                list.append(subList)
            }
        }
        return list
    }

    func fixGameBoard(tile: TileObject) {
        let (c, r) = tile.position
        let (c1, r1) = tile.prePositionFirst!
        if let (c2, r2) = tile.prePositionSecond {
            gameBoard[c2, r2] = EmptyTile(position: tile.prePositionFirst!)
        }
        gameBoard[c1, r1] = EmptyTile(position: tile.prePositionFirst!)
        gameBoard[c, r] = tile


        tile.clearOldMessage()
    }

    func notifyDelegateWithTile(tile: TileObject, isLast: Bool) {
        if tile.prePositionFirst != nil && tile.prePositionSecond != nil {
            // 移动两个
            delegate.moveTowFrom(tile.prePositionFirst!, from2: tile.prePositionSecond!, to: tile.position, value: tile.value, complete: {(flag) in
                if isLast {
                    self.finishMove()
                }
            })
        } else { // 移动一个
            delegate.moveOneFrom(tile.prePositionFirst!, to: tile.position, value: tile.value, mix: tile.mixed, complete: {(flag) in
                if isLast {
                    self.finishMove()
                }
            })
        }
    }

    // MARK: - 监测游戏状态
    func checkGameState() -> GameState {
        if gameHasWon() {return .Win}
        if gameHasLose() {return .Lose}
        return .Normal
    }

    // MARK: -  便捷方法
    func gameBoardEmptyList() -> [(Int, Int)] {
        var list = [(Int, Int)]()
        gameBoard.forEach {if $1.tileType == .Empty {list.append($0)}}
        return list
    }

    func gameBoardTileObjectList() -> [(Int, Int)] {
        var list = [(Int, Int)]()
        gameBoard.forEach {if $1.tileType == .Tile {list.append($0)}}
        return list
    }

    func gameHasWon() -> Bool {
        var win = false
        gameBoard.forEach {
            if let t = $1 as? TileObject {
                if t.value >= self.maxScore{
                    win = true
                }
            }
        }
        return win
    }

    func gameHasLose() -> Bool {
        return gameBoardEmptyList().count == 0 && !gameCanGoon()
    }

    func gameCanGoon() -> Bool {
        for i in 0..<gameBoard.dimension {
            for j in 0..<gameBoard.dimension {
                if i == gameBoard.dimension - 1 || j == gameBoard.dimension - 1 {continue}
                guard let tile = gameBoard[j, i] as? TileObject else {
                    return true
                }
                if let right = gameBoard[j + 1, i] as? TileObject {
                    if right.value == tile.value {
                        return true
                    }
                } else if let down = gameBoard[j, i + 1] as? TileObject {
                    if down.value == tile.value {
                        return true
                    }
                } else {
                    return true
                }
            }
        }
        return false
    }

    func resetGameLogic() {
        gameBoard.setAll(EmptyTile(position: (0, 0)))
        commondQueue.removeAll()
    }
}

// MARK: - 游戏棋盘
/**
 *  四方棋盘，使用泛型，内部存储对象可改变
 */
struct SquareGameBoard<T> {
    
    let dimension: Int
    var boardArray: [T]
    
    init(dimension d: Int, initialValue: T) {
        dimension = d
        boardArray = [T](count: d * d, repeatedValue: initialValue)
    }
    
    subscript(col: Int, row: Int) -> T {
        get {
            assert(col >= 0 && col < dimension, "column error")
            assert(row >= 0 && row < dimension, "row error")
            return boardArray[row * dimension + col];
        }
        set {
            assert(col >= 0 && col < dimension, "column error")
            assert(row >= 0 && row < dimension, "row error")
            return boardArray[row * dimension + col] = newValue;
        }
    }

    func forEach(closure: ((Int, Int), T) -> ()) {
        for i in 0..<dimension {
            for j in 0..<dimension {
                closure((j, i), self[j, i])
            }
        }
    }

    mutating func setAll(item: T) {
        for i in 0..<dimension {
            for j in 0..<dimension {
                self[i, j] = item
            }
        }
    }
}
