#
# Be sure to run `pod lib lint SwiftCamera.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|

  s.name         = "SwiftCamera"
  s.version      = "1.0.0"
  s.summary      = "Swift Camera"

  s.homepage     = "https://github.com/mohamedrias/SwiftCamera"
  
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Mohamed Rias" => "mohamedrias@gmail.com" }
  s.social_media_url   = "http://facebook.com/techieblogger"

  s.platform     = :ios
  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/mohamedrias/SwiftCamera.git", :tag => "1.0.0" }

  s.source_files  = "SwiftCamera", "SwiftCamera/Classes/*.swift"

  s.frameworks  = "UIKit", "AVFoundation", "CoreMedia", "CoreImage"

  s.requires_arc = true
  s.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS[config=Debug]' => '-D DEBUG' }

end