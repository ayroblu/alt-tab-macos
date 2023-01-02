import Swifter

let server = HttpServer()

func startServer() {
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
    server["/windows"] = { _ in getWindows() }
    server.PUT["/window/focus"] = focusWindow
    server.DELETE["/window"] = closeWindow
}

private func getWindows() -> HttpResponse {
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

    return HttpResponse.ok(.json(payload))
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
