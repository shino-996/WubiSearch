//: Playground - noun: a place where people can play

import UIKit

let utf8Str = "五"
let cfEncoding = CFStringEncodings.GB_18030_2000
let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
let gbkData = NSString(string: utf8Str).data(using: encoding)!
let gbkBytes = [UInt8](gbkData)
let percentStr = NSString(format: "%%%X%%%X", gbkBytes[0], gbkBytes[1])
