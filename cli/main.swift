//
//  main.swift
//  cli
//
//  Created by Ben Lu on 02/01/2023.
//  Copyright © 2023 lwouis. All rights reserved.
//

import Foundation

let port = "com.lwouis.alt-tab-macos" as CFString
guard let messagePort = CFMessagePortCreateRemote(nil, port) else {
  print("Alt-Tab.app is not open")
  exit(1)
}

var unmanagedData: Unmanaged<CFData>? = nil
let status = CFMessagePortSendRequest(messagePort, 0, Data("Hello111".utf8) as CFData, 3.0, 3.0, CFRunLoopMode.defaultMode.rawValue, &unmanagedData)
let cfData = unmanagedData?.takeRetainedValue()
if status == kCFMessagePortSuccess {
  if let data = cfData as Data? {
    if let JSONString = String(data: data, encoding: String.Encoding.utf8) {
       print(JSONString)
    }
//    if let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
//      print("payload", payload)
//    }
  } else {
    print("Couldn't convert data")
  }
} else {
  print("non success status", status)
}
