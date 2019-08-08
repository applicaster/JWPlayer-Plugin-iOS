Pod::Spec.new do |s|

  s.name             = "JWPlayerPlugin"
  s.version          = '3.1.0'
  s.summary          = 'JWPlayer Player plugin implementation.'
  s.description      = 'An implementation for JWPlayer as a Zapp Player Plugin in Objective C.'
  s.homepage         = "https://github.com/applicaster/JWPlayer-Plugin-iOS"
  s.license          = 'MIT'
  s.author           = { "Liviu Romascanu" => "l.romasca@applicaster.com" }
  s.source           = { :git => "git@github.com:applicaster/JWPlayer-Plugin-iOS.git", :tag => s.version.to_s }

  s.ios.deployment_target   = "10.0"
  s.platform                = :ios, '10.0'
  s.requires_arc            = true

  s.source_files = 'JWPlayerPlugin/**/*.{h,m}'

  s.xcconfig =  { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'ENABLE_BITCODE' => 'YES',
                  'OTHER_LDFLAGS' => '$(inherited)'
               }

  s.dependency 'ZappPlugins'
  s.dependency 'ApplicasterSDK'
  s.dependency 'ZappLoginPluginsSDK'
  s.dependency 'JWPlayer-SDK', '~> 3.0'

end
