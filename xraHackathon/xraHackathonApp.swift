//
//  xraHackathonApp.swift
//  xraHackathon
//
//  Created by iguest on 4/18/26.
//

import SwiftUI

@main
struct xraHackathonApp: App {
    var body: some Scene {
        WindowGroup {
            FreeFormDrawingView()
        }
        .windowStyle(.volumetric)
    }
}
