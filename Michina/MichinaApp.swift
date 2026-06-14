//
//  MichinaApp.swift
//  Michina
//
//  Created by Lucka on 2026-05-19.
//

import SwiftUI

@main
struct MichinaApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        MainScene()
        
        MenuBarExtraScene()
        
        InferenceScene()
        
        SettingsScene()
        
        OnboardingScene()
    }
}

fileprivate final class AppDelegate : NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = AppSettings.shared
        if !settings.presentRegularActivation {
            if settings.insertMenuBarExtra {
                NSApplication.shared.setActivationPolicy(.accessory)
            } else {
                settings.presentRegularActivation = true
            }
        }
        
        let _ = WebService.shared
    }
}
