Pod::Spec.new do |s|
  s.name             = 'OktaAuthSdk'
  s.version          = '2.0.1'
  s.summary          = 'SDK for Okta native authentication.'
  s.description      = <<-DESC
Integrate your native app with Okta.
                       DESC

  s.homepage         = 'https://github.com/okta/okta-auth-swift'
  s.license          = { :type => 'APACHE2', :file => 'LICENSE' }
  s.authors          = { "Okta Developers" => "developer@okta.com"}
  s.source           = { :git => 'https://github.com/okta/okta-auth-swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.source_files = 'Sources/**/*'
  s.swift_version = '4.2'
  s.exclude_files = [
    'Sources/OktaAuthNative/Info-iOS.plist',
    'Sources/OktaAuthNative/Info-macOS.plist',
    'Sources/OktaAuthNative/Info-tvOS.plist',
    'Sources/OktaAuthNative/Info-watchOS.plist'
  ]
end
