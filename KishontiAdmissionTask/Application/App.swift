//
//  KishontiAdmissionTaskApp.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 20..
//

import SwiftUI

@main
struct KishontiAdmissionTaskApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        LaunchScreen(config: LaunchScreenConfig.init(backgroundColor: Asset.accentColor.swiftUIColor)) {
            Image(.kishonti)
        } rootContent: {
            RootView()
        } loadingTask: {
            try? await Task.sleep(for: .seconds(2))
        }
    }
}
