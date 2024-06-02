Pod::Spec.new do |spec|
    spec.name                     = 'sorawallet'
    spec.version                  = '0.2.10'
    spec.homepage                 = 'Link to the Shared Module homepage'
    spec.source                   = { :git => 'https://github.com/soramitsu/x-networking-old.git', :tag => '0.2.10' }
    spec.authors                  = ''
    spec.license                  = ''
    spec.summary                  = 'Some description for the Shared Module'
    spec.vendored_frameworks      = 'lib/sorawallet/build/XCFrameworks/release/sorawallet.xcframework'
    spec.libraries                = 'c++'
    spec.ios.deployment_target = '11.0'
                
                
    spec.pod_target_xcconfig = {
        'KOTLIN_PROJECT_PATH' => ':core:sorawallet',
        'PRODUCT_MODULE_NAME' => 'XNetworking.SoraWallet',
    }
                
end