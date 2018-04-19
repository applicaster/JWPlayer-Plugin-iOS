Pod::Spec.new do |s|

  s.name             = "JWPlayer-Plugin-iOS"
  s.version          = '1.0.3'
  s.summary          = "An EXample of video player framework for Zapp iOS."
  s.description      = <<-DESC
                        An EXample of video player framework for Zapp iOS.
                       DESC
  s.homepage         = "https://github.com/applicaster/JWPlayer-Plugin-iOS"
  s.license          = 'MIT'
  s.author           = { "Udi Lumnitz" => "u.lumnitz@applicaster.com" }
  s.source           = { :git => "git@github.com:applicaster/JWPlayer-Plugin-iOS.git", :tag => s.version.to_s }

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.public_header_files = 'Classes/**/*.h'
  s.source_files = 'Classes/**/*.{h,m,swift}'

  s.xcconfig =  { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                  'ENABLE_BITCODE' => 'NO',
                  'OTHER_LDFLAGS' => '$(inherited)',
                  'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**',
                  'LIBRARY_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}"/**'
                }

  s.dependency 'ZappPlugins'
  s.dependency 'ApplicasterSDK'
  s.dependency 'JWPlayer-SDK', '~> 2.8'

end
