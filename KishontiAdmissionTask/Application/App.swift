//
//  KishontiAdmissionTaskApp.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI
import FactoryKit

@main
struct KishontiAdmissionTaskApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate
    
//    @StateObject private var peerService = GeneratedMultipeerService()

    let dispatcher: ActionDispatcher = Container.shared.actionDispatcher()
    let systemService: SystemService = Container.shared.systemService()

    init() {
        Container.shared.preInit()
    }

    var body: some Scene {
        LaunchScreen(config: LaunchScreenConfig.init(backgroundColor: Asset.accentColor.swiftUIColor)) {
            Image(.kishonti)
        } rootContent: {
            RootView()
        } loadingTask: {
            await systemService.start()
            try? await Task.sleep(for: .seconds(1))
        }
        .environment(\.dispatcher, dispatcher)
    }
}
