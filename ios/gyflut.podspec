#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'gyflut'
  s.version          = '0.0.1'
  s.summary          = 'gysdk plugin flutter'
  s.description      = <<-DESC
getui plugin flutter
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'GYSDK'

  s.ios.deployment_target = '11.0'
  s.static_framework = true
end

