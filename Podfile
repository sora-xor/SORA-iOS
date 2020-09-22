platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'

abstract_target 'SoraPassportAll' do
  use_frameworks!

  pod 'SwiftLint'
  pod 'R.swift', :inhibit_warnings => true
  pod 'FireMock', :inhibit_warnings => true
  pod 'GCDWebServer', :inhibit_warnings => true
  pod 'SoraDocuments'
  pod 'SoraCrypto'
  pod 'SoraKeystore'
  pod 'SoraUI'
  pod 'RobinHood'
  pod 'Kingfisher', :inhibit_warnings => true
  pod 'CommonWallet', :git => 'https://github.com/soramitsu/Capital-iOS.git', :commit => 'ef5c8a1bcc8437df1cff196b8698752476471d3a'
  pod 'FirebaseMessaging'
  pod 'Firebase/Crashlytics'
  pod 'FirebaseAnalytics'
  pod 'ReachabilitySwift'
  pod 'SwiftyBeaver'
  pod 'SKPhotoBrowser'
  pod 'SoraFoundation', '~> 0.8.0'
  pod 'web3swift'
  pod 'IrohaCrypto'
  pod 'IKEventSource'

  target 'SoraPassportTests' do
      inherit! :search_paths
      
      pod 'Cuckoo'
      pod 'FireMock'
      pod 'SoraUI'
      pod 'SoraDocuments'
      pod 'SoraCrypto'
      pod 'SoraKeystore'
      pod 'RobinHood'
      pod 'IrohaCrypto'
      pod 'CommonWallet', :git => 'https://github.com/soramitsu/Capital-iOS.git', :commit => 'ef5c8a1bcc8437df1cff196b8698752476471d3a'
      pod 'SoraFoundation', '~> 0.8.0'
      pod 'web3swift'
  end
  
  target 'SoraPassportUITests' do
      inherit! :search_paths
  end

  target 'SoraPassportIntegrationTests'

  target 'SoraPassport'
  
end

post_install do |installer|
  installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
    configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
  end
end
