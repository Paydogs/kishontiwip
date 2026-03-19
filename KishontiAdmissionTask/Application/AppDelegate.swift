//
//  AppDelegate.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 18..
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
   
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("didFinishLaunchingWithOptions")
        
        AppleLoggerAdapter.bootstrapStandardOutputWithLogLevel(level: .trace)
        Log.install(AppleLoggerAdapter())
        
        return true
    }

    // Example: push registration callback
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
//        appController?.didRegisterForPush(deviceToken: deviceToken)
    }
    
    // Push, background tasks, deep links go here
}
