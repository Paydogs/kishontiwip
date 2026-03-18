//
//  LaunchScreen.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import SwiftUI

struct LaunchScreen<RootView: View, Logo: View>: Scene {
    var config: LaunchScreenConfig = .init()
    
    @ViewBuilder var logoContent: () -> Logo
    @ViewBuilder var rootContent: RootView
    var loadingTask: (() async -> Void)?
    
    var body: some Scene {
        WindowGroup {
            rootContent
                .modifier(LaunchScreenModifier(config: config, loadingTask: loadingTask, logo: logoContent))
        }
    }
}

fileprivate struct LaunchScreenModifier<Logo: View>: ViewModifier {
    var config: LaunchScreenConfig
    var loadingTask: (() async -> Void)?
    @ViewBuilder var logo: Logo
    
    // MARK: Private properties
    @Environment(\.scenePhase) private var scenePhase
    @State private var splashWindow: UIWindow?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                let scenes = UIApplication.shared.connectedScenes
                
                for scene in scenes {
                    guard let windowScene = scene as? UIWindowScene,
                          checkStates(windowScene.activationState),
                          !windowScene.windows.contains(where: { $0.tag == 9999 })
                    else {
                        print("SplashWindow already added")
                        continue
                    }
                    
                    let window = makeSplashWindow(with: windowScene)
                    
                    let loadingView = LaunchScreenView(config: config, loadingTask: loadingTask) { logo }
                    isCompleted: {
                        window.isHidden = true
                        self.splashWindow = nil
                    }
                    
                    let animationRootViewController = UIHostingController(rootView: loadingView)
                    animationRootViewController.view.backgroundColor = .clear
                    window.rootViewController = animationRootViewController
                    
                    self.splashWindow = window
                    print("SplashWindow added")
                }
            }
    }
    
    private func checkStates(_ state: UIWindowScene.ActivationState) -> Bool {
        switch scenePhase {
        case .active: return state == .foregroundActive
        case .inactive: return state == .foregroundInactive
        case .background: return state == .background
        default: return state.hashValue == scenePhase.hashValue
        }
    }
    
    private func makeSplashWindow(with windowScene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .clear
        window.isHidden = false
        window.isUserInteractionEnabled = false
        window.windowLevel = .normal + 1
        
        return window
    }
}

fileprivate struct LaunchScreenView<Logo: View>: View {
    var config: LaunchScreenConfig
    var loadingTask: (() async -> Void)?
    @ViewBuilder var logo: Logo
    var isCompleted: () -> Void
    
    @State private var startAnimation = false
    @State private var contentOpacity = 1.0
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(config.backgroundColor)
                .mask(
                    ZStack {
                        Rectangle()
                        logo
                            .scaleEffect(startAnimation ? config.scaling : 1.0)
                            .frame(width: 100, height: 100)
                            .blendMode(.destinationOut)
                    }
                )
            
            logo
                .frame(width: 100, height: 100)
                .opacity(startAnimation ? 0 : 1)
                .animation(nil, value: startAnimation)
        }
        .compositingGroup()
        .opacity(contentOpacity)
        .ignoresSafeArea()
        .task {
            if let loadingTask = loadingTask {
                await loadingTask()
            } else {
                try? await Task.sleep(for: Duration.seconds(config.initialDelay))
            }
            
            await animate()
        }
    }
    
    private func animate() async {
        withAnimation(.easeIn(duration: config.animationDuration)) {
            startAnimation = true
        }
        try? await Task.sleep(for: .seconds(config.animationDuration * 0.5))
        withAnimation(.easeIn(duration: config.animationDuration * 0.5)) {
            contentOpacity = 0
        }
        try? await Task.sleep(for: .seconds(config.animationDuration * 0.5))
        isCompleted()
    }
}
