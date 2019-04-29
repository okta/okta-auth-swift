Pod::Spec.new do |s|
  s.name             = 'OktaAuthSdk'
  s.version          = '1.0.0'
  s.summary          = 'SDK for Okta native authentication.'
  s.description      = <<-DESC
Integrate your native app with Okta.
                       DESC

  s.homepage         = 'https://github.com/okta/okta-auth-swift'
  s.license          = { :type => 'APACHE2', :file => 'LICENSE' }
  s.authors          = { "Okta Developers" => "developer@okta.com"}
  s.source           = { :git => 'https://github.com/okta/okta-auth-swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.source_files = 'Source/**/*'
  s.exclude_files = [
    'Source/Info.plist'
  ]
end
