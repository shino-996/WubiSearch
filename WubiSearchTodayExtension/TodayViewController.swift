//
//  TodayViewController.swift
//  WubiSearchTodayExtension
//
//  Created by shino on 2017/8/9.
//  Copyright © 2017年 shino. All rights reserved.
//

import UIKit
import NotificationCenter
import Fuzi
import PromiseKit

fileprivate extension String {
    var stringWithGBKPercentEncode: String {
        get {
            let cfEncoding = CFStringEncodings.GB_18030_2000
            let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
            let gbkData = (self as NSString).data(using: encoding)!
            let gbkBytes = [UInt8](gbkData)
            return NSString(format: "%%%X%%%X", gbkBytes[0], gbkBytes[1]) as String
        }
        
    }
    
    init?(gbkData: Data) {
        let cfEncoding = CFStringEncodings.GB_18030_2000
        let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
        if let str = NSString(data: gbkData, encoding: encoding) {
            self = str as String
        } else {
            return nil
        }
    }
}

class TodayViewController: UIViewController, NCWidgetProviding {
    var searchCharacter: String!
        
    @IBOutlet weak var characterView: UIStackView!
    @IBOutlet weak var characterLabel: UILabel!
    @IBOutlet weak var speakLabel: UILabel!
    @IBOutlet weak var speakImage: UIImageView!
    
    @IBOutlet weak var searchButton: UIButton!
    @IBAction func fetchData() {
        searchButton.isHidden = true
        firstly { () -> URLDataPromise in
            let url = URL(string: "http://www.52wubi.com/wbbmcx/search.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = ("hzname=" + searchCharacter!).data(using: .ascii)
            return URLSession(configuration: .ephemeral).dataTask(with: request)
        }.then { (data: Data) -> URLDataPromise in
            let str = String(gbkData: data)
            let parseStr = try! HTMLDocument(string: str!)
            let wubiCode = parseStr.body?
                .children[2].children[3].children[0].children[1]
                .children[3].children[0].children[1].children[2].stringValue
            DispatchQueue.main.async {
                self.characterView.isHidden = false
                self.speakLabel.isHidden = false
                self.speakLabel.text = wubiCode!
            }
            let wubiImageURL = "http://www.52wubi.com/wbbmcx/" + (parseStr.body?
                .children[2].children[3].children[0].children[1]
                .children[3].children[0].children[1].children[3]
                .children[0].attr("src"))!
            let imageURL = URL(string: wubiImageURL.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!
            let request = URLRequest(url: imageURL)
            return URLSession(configuration: .ephemeral).dataTask(with: request)
        }.then { (data: Data) -> Void in
            let image = UIImage(data: data)
            DispatchQueue.main.async {
                self.speakImage.isHidden = false
                self.speakImage.image = image
            }
        }.catch { _ in }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        characterView.isHidden = true
        searchButton.isHidden = false
        searchButton.isEnabled = false
        let character = UIPasteboard.general.string
        guard character?.characters.count == 1 else {
            completionHandler(NCUpdateResult.newData)
            searchButton.setTitle("复制单个汉字拷贝以查询", for: .normal)
            return
        }
        searchButton.isEnabled = true
        searchCharacter = character!.stringWithGBKPercentEncode
        characterLabel?.text = character!
        searchButton.setTitle("当前剪切板里的汉字：" + character!, for: .normal)
        completionHandler(NCUpdateResult.newData)
    }
    
}
