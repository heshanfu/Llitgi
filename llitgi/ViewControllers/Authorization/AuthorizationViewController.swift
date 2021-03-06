//
//  AuthorizationViewController.swift
//  llitgi
//
//  Created by Xavi Moll on 24/12/2017.
//  Copyright © 2017 xmollv. All rights reserved.
//

import UIKit
import SafariServices

class AuthorizationViewController: UIViewController {
    
    //MARK:- IBOutlets
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var offlineImageView: UIImageView!
    @IBOutlet private var offlineTitleLabel: UILabel!
    @IBOutlet private var offlineDescriptionLabel: UILabel!
    @IBOutlet private var syncImageView: UIImageView!
    @IBOutlet private var syncTitleLabel: UILabel!
    @IBOutlet private var syncDescriptionLabel: UILabel!
    @IBOutlet private var minimalistImageView: UIImageView!
    @IBOutlet private var minimalistTitleLabel: UILabel!
    @IBOutlet private var minimalistDescriptionLabel: UILabel!
    @IBOutlet private var actionButton: UIButton!
    
    //MARK: Private properties
    private let dataProvider: DataProvider
    private let themeManager: ThemeManager
    
    //MARK: Public properties
    var loginFinished: (() -> Void)?
    var safariToPresent: ((SFSafariViewController) -> Void)?
    
    //MARK:- Lifecycle
    init(dataProvider: DataProvider, themeManager: ThemeManager) {
        self.dataProvider = dataProvider
        self.themeManager = themeManager
        super.init(nibName: String(describing: AuthorizationViewController.self), bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.apply(self.themeManager.theme)
        self.themeManager.themeChanged = { [weak self] theme in
            self?.apply(theme)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.verifyCodeAndGetToken), name: .OAuthFinished, object: nil)
        self.setupLocalizedStrings()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: IBActions
    @IBAction private func actionButtonTapped(_ sender: UIButton) {
        sender.isEnabled = false
        // Step 1. Grab the token to initiate the OAuth steps
        self.dataProvider.performInMemory(endpoint: .requestToken) { [weak self] (result: Result<[RequestTokenResponse]>) in
            sender.isEnabled = true
            guard let strongSelf = self else { return }
            switch result {
            case .isSuccess(let tokenResponse):
                guard let code = tokenResponse.first?.code else {
                    strongSelf.presentErrorAlert()
                    Logger.log("The tokenResponse was an empty array.", event: .error)
                    return
                }
                strongSelf.dataProvider.updatePocket(code: code)
                
                // Step 2. Open Safari to perform the Oauth
                if UIApplication.shared.canOpenURL(URL(string: "pocket-oauth-v1://")!) {
                    guard let url = strongSelf.dataProvider.pocketOAuthUrls.app else { return }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    guard let url = strongSelf.dataProvider.pocketOAuthUrls.web else { return }
                    let sfs = SFSafariViewController(url: url)
                    sfs.modalPresentationStyle = .formSheet
                    sfs.preferredControlTintColor = strongSelf.themeManager.theme.tintColor
                    sfs.preferredBarTintColor = strongSelf.themeManager.theme.backgroundColor
                    strongSelf.safariToPresent?(sfs)
                }
                
            case .isFailure(let error):
                strongSelf.presentErrorAlert()
                Logger.log(error.localizedDescription, event: .error)
            }
        }
    }
    
    //MARK: Private methods
    private func apply(_ theme: Theme) {
        self.view.backgroundColor = theme.backgroundColor
        self.titleLabel.textColor = theme.textTitleColor
        self.offlineImageView.tintColor = theme.textTitleColor
        self.offlineTitleLabel.textColor = theme.textTitleColor
        self.offlineDescriptionLabel.textColor = theme.textSubtitleColor
        self.syncImageView.tintColor = theme.textTitleColor
        self.syncTitleLabel.textColor = theme.textTitleColor
        self.syncDescriptionLabel.textColor = theme.textSubtitleColor
        self.minimalistImageView.tintColor = theme.textTitleColor
        self.minimalistTitleLabel.textColor = theme.textTitleColor
        self.minimalistDescriptionLabel.textColor = theme.textSubtitleColor
        switch theme {
        case .light:
            self.actionButton.backgroundColor = .black
            self.actionButton.setTitleColor(.white, for: .normal)
            self.actionButton.borderColor = .black
            self.actionButton.borderWidth = 1
        case .dark:
            self.actionButton.backgroundColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
            self.actionButton.setTitleColor(.white, for: .normal)
            self.actionButton.borderColor = .white
            self.actionButton.borderWidth = 1
        }
        
    }
    
    private func setupLocalizedStrings() {
        self.titleLabel.text = L10n.Onboarding.title
        self.offlineTitleLabel.text = L10n.Onboarding.offlineTitle
        self.offlineDescriptionLabel.text = L10n.Onboarding.offlineDescription
        self.syncTitleLabel.text = L10n.Onboarding.syncTitle
        self.syncDescriptionLabel.text = L10n.Onboarding.syncDescription
        self.minimalistTitleLabel.text = L10n.Onboarding.minimalistTitle
        self.minimalistDescriptionLabel.text = L10n.Onboarding.minimalistDescription
        self.actionButton.setTitle(L10n.Onboarding.button, for: .normal)
    }
    
    //Step 3. Verify the code against the API once the user has finished the OAuth flow
    @objc private func verifyCodeAndGetToken() {
        self.dismiss(animated: false, completion: nil)
        self.dataProvider.performInMemory(endpoint: .authorize) { [weak self] (result: Result<[AuthorizeTokenResponse]>) in
            guard let strongSelf = self else { return }
            switch result {
            case .isSuccess(let tokenResponse):
                guard let token = tokenResponse.first?.accessToken else {
                    strongSelf.presentErrorAlert()
                    Logger.log("The tokenResponse was an empty array.", event: .error)
                    return
                }
                strongSelf.dataProvider.updatePocket(token: token)
                strongSelf.loginFinished?()
            case .isFailure(let error):
                strongSelf.presentErrorAlert()
                Logger.log(error.localizedDescription, event: .error)
            }
        }
    }

}
