//
//  ViewController.swift
//  My2048
//
//  Created by JMacMini on 16/4/29.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let vc = GameViewController(enableCornerDirection: true);
        presentViewController(vc, animated: true, completion: nil)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

}

