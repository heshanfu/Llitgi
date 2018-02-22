//
//  AppDelegate.swift
//  llitgi
//
//  Created by Xavi Moll on 24/12/2017.
//  Copyright © 2017 xmollv. All rights reserved.
//

import UIKit
import CoreSpotlight

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let modelFactory: CoreDataFactory = CoreDataFactoryImplementation()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Initialization of dependencies
        let pocketAPI = PocketAPIManager()
        let dataProvider = DataProvider(pocketAPI: pocketAPI, modelFactory: modelFactory)
        let syncManager = SyncManager(dataProvider: dataProvider)
        let userPreferences = UserPreferencesManager()
        let dependencies = Dependencies(dataProvider: dataProvider, syncManager: syncManager, userPreferences: userPreferences)
        let viewControllerFactory = ViewControllerFactory(dependencies: dependencies)
        
        let rootViewController = TabBarController(factory: viewControllerFactory)
        if let _ = LlitgiUserDefaults.shared.string(forKey: kAccesToken) {
            rootViewController.setupMainFlow()
        } else {
            rootViewController.setupAuthFlow()
        }
        
        // Establishing the window and rootViewController
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.makeKeyAndVisible()
        self.window?.tintColor = .black
        self.window?.rootViewController = rootViewController
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handles the callback from the pocket app/website
        if url.scheme == "xmollv-llitgi" && url.host == "pocketAuth" {
            Logger.log("Auth finished")
            NotificationCenter.default.post(name: .OAuthFinished, object: nil)
        }
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == CSSearchableItemActionType {
            if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                guard let item = self.modelFactory.hasItem(identifiedBy: uniqueIdentifier) else { return false }
                guard let tabBarController = application.keyWindow?.rootViewController as? TabBarController else { return false }
                guard let viewControllers = tabBarController.viewControllers else { return false}
                guard viewControllers.count == 5 else { return false }
                tabBarController.selectedIndex = 3
                guard let search = (viewControllers[3] as? UINavigationController)?.topViewController as? SearchViewController else { return false }
                _ = search.view
                search.searchFromSpotlight(item: item)
            }
        }
        
        return true
    }

}

