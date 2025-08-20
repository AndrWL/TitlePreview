//
//  TitlePreviewApp.swift
//  TitlePreview
//
//  Created by ANDRII LEBEDIEV on 19.08.2025.
//

import ComposableArchitecture
import Firebase
import SwiftUI

@main
struct TitlePreviewApp: App {
    init() { FirebaseApp.configure() }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(
                initialState: AppFeature.State()) {
                    AppFeature()
                }
            )
        }
    }
}
