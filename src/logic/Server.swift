import Swifter

let server = HttpServer()

func startServer() {
    createMessagePort()
    setEndpoints()
    do {
        try server.start(9999, forceIPv4: true)
        print("Server has started (port: \(try server.port()))")
    } catch {
        print("Server start error: \(error)")
    }
}

func stopServer() {
    server.stop()
}

private func setEndpoints() {
    server["/"] = { request in HttpResponse.ok(.text("{}")) }
    server["/windows"] = getWindowsHttp
    server.POST["/window/image"] = windowImage
    server.PUT["/window/focus"] = focusWindow
    server.DELETE["/window"] = closeWindow
}

private func getWindowsHttp(_ request: HttpRequest) -> HttpResponse {
    let payload = getWindows()
    return HttpResponse.ok(.json(payload))
}
private func getWindows() -> [String: Any] {
    let windowData = Windows.list.map({
        [
            "name": $0.title ?? "(Unknown)", "isFullscreen": $0.isFullscreen,
            "isMinimized": $0.isMinimized, "spaceIndex": $0.spaceIndex,
            "lastFocusOrder": $0.lastFocusOrder,
            "position": ["x": $0.position?.x, "y": $0.position?.y],
            "size": ["width": $0.size?.width, "height": $0.size?.height],
            "application": $0.application.runningApplication.localizedName ?? "(Unknown)",
            "applicationBundleUrl": $0.application.runningApplication.bundleURL?.absoluteString
                ?? "file:///", "windowId": $0.cgWindowId, "isHidden": $0.isHidden,
            "isWindowlessApp": $0.isWindowlessApp,
        ]
    })

    let payload: [String: Any] = ["windows": windowData, "version": 1]

    return payload
}

private func focusWindow(_ request: HttpRequest) -> HttpResponse {
    let form = request.parseUrlencodedForm()
    return form.first { $0.0 == "windowId" }
        .flatMap { Int($0.1) }
        .flatMap { windowId in
            Windows.list.first { $0.cgWindowId.map {$0 == windowId} ?? false }
        }.map { $0.focus() }
        .map {
            HttpResponse.ok(.text(""))
        } ?? HttpResponse.badRequest(.text(""))
}

private func closeWindow(_ request: HttpRequest) -> HttpResponse {
    let form = request.parseUrlencodedForm()

    return form.first { $0.0 == "windowId" }
        .flatMap { Int($0.1) }
        .flatMap { windowId in
            Windows.list.first { $0.cgWindowId.map { $0 == windowId } ?? false }
        }.map({ window in
            window.close()
        }).map({ _ in
            HttpResponse.ok(.text(""))
        }) ?? HttpResponse.badRequest(.text(""))
}

private func windowImage(_ request: HttpRequest) -> HttpResponse {
    let form = request.parseUrlencodedForm()
    return form.first { $0.0 == "windowId" }
        .flatMap { Int($0.1) }
        .flatMap { windowId in
            Windows.list.first { $0.cgWindowId.map {$0 == windowId} ?? false }
        }.flatMap { w in
          w.thumbnail?.pngData
        }.map { data in
          HttpResponse.ok(.data(data))
        } ?? HttpResponse.badRequest(.text(""))
}
private func saveImage(windowId: CGWindowID, image: NSImage) -> Bool {
  let destinationURL = URL(fileURLWithPath: "/tmp").appendingPathComponent("alt-tab-\(windowId).png")
  return image.pngWrite(to: destinationURL)
}
extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

var callback: CFMessagePortCallBack = { messagePort, messageID, cfData, info in
  guard let dataReceived = cfData as Data?,
        let string = String(data: dataReceived, encoding: .utf8) else {
    return nil
  }
  print("callback", string)
  let payload = getWindows()
  guard let dataToSend = try? JSONSerialization.data(withJSONObject: payload) else {
    print("not convertible data")
    return nil
  }
//  let dataToSend = Data("finished".utf8)
  return Unmanaged.passRetained(dataToSend as CFData)
}

func createMessagePort() {
  var context = CFMessagePortContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
  let port = "com.lwouis.alt-tab-macos" as CFString
  if let messagePort = CFMessagePortCreateLocal(nil, port, callback, &context, nil),
     let source = CFMessagePortCreateRunLoopSource(nil, messagePort, 0) {
    CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
  }
}
