platform :ios, '9.0'
use_frameworks!
install! 'cocoapods', :deterministic_uuids => false

source 'https://github.com/applicaster/CocoaPods.git'
source 'https://github.com/applicaster/PluginsBuilderCocoaPods.git'
source 'https://github.com/CocoaPods/Specs.git'

def shared_pods
pod 'ZappPlugins'
pod 'ApplicasterSDK'
pod 'JWPlayer-SDK', '~> 2.8'
end

target 'JWPlayer-Plugin-iOS' do
    #shared_pods
    pod 'JWPlayer-Plugin-iOS', :path => '.'
end

