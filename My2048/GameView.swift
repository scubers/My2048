//
//  GameView.swift
//  My2048
//
//  Created by JMacMini on 16/4/29.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import UIKit

class GameView: UIView {
    
    var dimension: Int = 0 ///< 棋盘尺寸
    var gap: CGFloat = 10.0 ///< 棋盘间隔
    var corner: CGFloat = 6.0
    
    var tileColor: UIColor = UIColor.lightGrayColor()
    var tileLayers: [CALayer] = [CALayer]()
    
    // NSIndexPath -> row for row, section for column
    var tileViews: [NSIndexPath : TileView] = [NSIndexPath : TileView]()
    
    var animateDuration = 0.1
    
    
    var tileSize: CGSize {
        get {
            let width = (frame.width - (gap) * CGFloat(dimension + 1)) / CGFloat(dimension)
            let height = width
            return CGSizeMake(width, height)
        }
    }

    // MARK: - 初始化
    private override init(frame: CGRect) {
        super.init(frame: frame);
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    convenience init(dimension d: Int, gap g: CGFloat, corner c: CGFloat) {
        self.init()
        dimension = d
        gap = g
        corner = c
        self.clipsToBounds = true
        setupUI()
    }
    
    func setupUI() {

        tileLayers.forEach {$0.removeFromSuperlayer()}
        tileLayers.removeAll()
        self.subviews.forEach {$0.removeFromSuperview()}

        self.layer.cornerRadius = corner
        self.backgroundColor = UIColor.blackColor()

        for _ in 0..<dimension*dimension {
            let tileLayer = CALayer()
            tileLayer.backgroundColor = tileColor.CGColor
            tileLayer.cornerRadius = corner
            tileLayer.masksToBounds = true
            layer.addSublayer(tileLayer)
            tileLayers.append(tileLayer)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        for (idx, tileLayer) in tileLayers.enumerate() {
            let col = idx % dimension
            let row = idx / dimension
            tileLayer.frame = frameForTileAtColumn(col, row: row)
        }
    }
    
    func frameForTileAtColumn(column: Int, row: Int) -> CGRect {
        let width = tileSize.width
        let height = tileSize.height
        let x = CGFloat(column) * width + gap * (CGFloat(column + 1))
        let y = CGFloat(row) * height + gap * (CGFloat(row + 1))
        return CGRectMake(x, y, width, height)
    }

    func resetGameView() {
        tileViews.removeAll()
        self.subviews.forEach {$0.removeFromSuperview()}
        setupUI()
    }
    
    // MARK: - 操作方法
    func insertTileAtIndexPath(indexpath: NSIndexPath, value: Int) {
        if tileViews[indexpath] != nil {
            assert(false, "placeholder error")
        }
        
        assert(indexpath.section >= 0 && indexpath.row >= 0 && indexpath.section < dimension && indexpath.row < dimension, "indexpath error");
        
        let tile = TileView(value: value, corner: corner)
//        tile.backgroundColor = UIColor.blueColor()
        tile.frame = frameForTileAtColumn(indexpath.section, row: indexpath.row)
        tile.value = value
        tileViews[indexpath] = tile
        self.addSubview(tile)

        self.bringSubviewToFront(tile)

        // TODO: 执行动画
        appearAnimate(tile)

    }

    func appearAnimate(tileView: TileView) {
        tileView.transform = CGAffineTransformMakeScale(0.1, 0.1)
        UIView.animateWithDuration(0.1, animations: {
            tileView.transform = CGAffineTransformIdentity
        }) { (flag) in
        }
    }
    
    // 移动一个瓦片去某个位置，有可能合并
    func moveOneTile(from f: NSIndexPath, to: NSIndexPath, value: Int, mixed: Bool, complete: ((Bool)->())?) {
        guard let fromTile = tileViews.removeValueForKey(f) else {
            assert(false, "source nil error")
        }
        let toTile = tileViews.removeValueForKey(to)
        tileViews[to] = fromTile

        let toFrame = frameForTileAtColumn(to.section, row: to.row)
        UIView.animateWithDuration(animateDuration, animations: {
            fromTile.frame = toFrame
            fromTile.value = value
        }) { (flag) in
            toTile?.removeFromSuperview()
            if mixed {
                self.mixAnimate(fromTile, complete: complete)
            } else {
                complete?(flag)
            }
        }
    }


    // 移动两个瓦片去某个位置，合并
    func moveTwoTile(first f1: NSIndexPath, second f2: NSIndexPath, to: NSIndexPath, value: Int, complete: ((Bool)->())?) {
        guard let from1 = tileViews.removeValueForKey(f1) else {
            assert(false, "source1 nil error")
        }
        guard let from2 = tileViews.removeValueForKey(f2) else {
            assert(false, "source2 nil error")
        }
        self.tileViews[to] = from1

        let toFrame = frameForTileAtColumn(to.section, row: to.row)
        UIView.animateWithDuration(animateDuration, animations: {
            from1.frame = toFrame
            from2.frame = toFrame
            from1.value = value
        }) { (flag) in
            from2.removeFromSuperview()
            self.mixAnimate(from1, complete: complete)
        }
    }

    func mixAnimate(tileView: TileView, complete: ((Bool)->())?) {
        UIView.animateWithDuration(0.1, animations: {
            tileView.transform = CGAffineTransformMakeScale(1.2, 1.2)
        }) { (flag) in
            UIView.animateWithDuration(0.1, animations: { 
                tileView.transform = CGAffineTransformIdentity
            }, completion: { (flag) in
                complete?(flag)
            })
        }
    }
}

// MARK: - TileView
class TileView : UIView {
    
    var label: UILabel!
    
    var value: Int = 2 {
        didSet {
            backgroundColor = color4Value(value: value)
            label.textColor = numberColor(value: value)
            label.text = "\(value)"
        }
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        label = UILabel()
        label.font = fontForNumbers()
        label.textAlignment = .Center
        label.adjustsFontSizeToFitWidth = true
        addSubview(label)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(value: Int, corner: CGFloat) {
        self.init()
        self.value = value
        layer.cornerRadius = corner
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
    
    private func color4Value(value v: Int) -> UIColor {
        switch v {
        case 2:
            return UIColor(red: 238.0/255.0, green: 228.0/255.0, blue: 218.0/255.0, alpha: 1.0)
        case 4:
            return UIColor(red: 237.0/255.0, green: 224.0/255.0, blue: 200.0/255.0, alpha: 1.0)
        case 8:
            return UIColor(red: 242.0/255.0, green: 177.0/255.0, blue: 121.0/255.0, alpha: 1.0)
        case 16:
            return UIColor(red: 245.0/255.0, green: 149.0/255.0, blue: 99.0/255.0, alpha: 1.0)
        case 32:
            return UIColor(red: 246.0/255.0, green: 124.0/255.0, blue: 95.0/255.0, alpha: 1.0)
        case 64:
            return UIColor(red: 246.0/255.0, green: 94.0/255.0, blue: 59.0/255.0, alpha: 1.0)
        case 128, 256, 512, 1024, 2048:
            return UIColor(red: 237.0/255.0, green: 207.0/255.0, blue: 114.0/255.0, alpha: 1.0)
        default:
            return UIColor.blackColor()
        }
    }

    // MARK: - Provide a numeral color for a given value
    private func numberColor(value v: Int) -> UIColor {
        switch v {
        case 2, 4:
            return UIColor(red: 119.0/255.0, green: 110.0/255.0, blue: 101.0/255.0, alpha: 1.0)
        default:
            return UIColor.whiteColor()
        }
    }

    // MARK: - Provide the font to be used on the number tiles
    private func fontForNumbers() -> UIFont {
        if let font = UIFont(name: "HelveticaNeue-Bold", size: 20) {
            return font
        }
        return UIFont.systemFontOfSize(20)
    }
}


