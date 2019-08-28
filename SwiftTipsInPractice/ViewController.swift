//
//  ViewController.swift
//  SwiftTipsInPractice
//
//  Created by kingcos on 2019/8/29.
//  Copyright © 2019 kingcos. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        var vc: UIViewController
        
        switch indexPath.row {
        case 0:
            vc = Demo100ViewController()
        case 1:
            vc = Demo99ViewController()
        default:
            vc = UIViewController()
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
}

