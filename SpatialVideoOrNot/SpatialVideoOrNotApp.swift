//
//  SpatialVideoOrNotApp.swift
//  SpatialVideoOrNot
//
//  Created by Cristian Díaz Peredo on 02.06.24.
//

import SwiftUI

@main
struct SpatialVideoOrNotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
