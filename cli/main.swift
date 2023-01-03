//
//  main.swift
//  cli
//
//  Created by Ben Lu on 02/01/2023.
//  Copyright © 2023 lwouis. All rights reserved.
//

import Foundation

if let arg1 = CommandLine.arguments[safe: 1] {
  switch arg1 {
  case "windows":
      let data = sendMessageData(messageId: MessageType.windows.rawValue, messageData: Data("".utf8))
      if let data = data, let JsonString = String(data: data, encoding: String.Encoding.utf8) {
        print(JsonString)
      }
  case "image":
      if let windowId = CommandLine.arguments[safe: 2] {
          let data = sendMessageData(messageId: MessageType.image.rawValue, messageData: Data(windowId.utf8))
          if let data = data, let JsonString = String(data: data, encoding: String.Encoding.utf8) {
            print(JsonString)
          }
      } else {
          earlyExit()
      }
  case "focus":
      if let windowId = CommandLine.arguments[safe: 2] {
          let data = sendMessageData(messageId: MessageType.focus.rawValue, messageData: Data(windowId.utf8))
          if let data = data, let JsonString = String(data: data, encoding: String.Encoding.utf8) {
            print(JsonString)
          }
      } else {
          earlyExit()
      }
  case "close":
      if let windowId = CommandLine.arguments[safe: 2] {
          let data = sendMessageData(messageId: MessageType.close.rawValue, messageData: Data(windowId.utf8))
          if let data = data, let JsonString = String(data: data, encoding: String.Encoding.utf8) {
            print(JsonString)
          }
      } else {
          earlyExit()
      }
  default:
      earlyExit()
  }
}
func earlyExit() {
    print("""
alt-tab-cli
A cli to interact with AltTab

USAGE:
    alt-tab-cli <SUBCOMMAND>

SUBCOMMANDS:
    windows
        Get the list of all windows that are open
    image <window-id>
        Get the thumbnail image for the application
    focus <window-id>
        Focus on the window id provided
    close <window-id>
        Close the window id provided
""")
    exit(2)
}

let port = "com.lwouis.alt-tab-macos" as CFString
func sendMessageData(messageId: Int, messageData: Data) -> Data? {
  guard let messagePort = CFMessagePortCreateRemote(nil, port) else {
    print("Alt-Tab.app is not open")
    return nil
  }

  var unmanagedData: Unmanaged<CFData>? = nil
  let status = CFMessagePortSendRequest(messagePort, Int32(messageId), messageData as CFData, 3.0, 3.0, CFRunLoopMode.defaultMode.rawValue, &unmanagedData)
  let cfData = unmanagedData?.takeRetainedValue()
  if status == kCFMessagePortSuccess {
    return cfData as Data?
  } else {
    print("non success status", status)
    return nil
  }
}
enum MessageType: Int {
  case windows = 0, image, focus, close
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
