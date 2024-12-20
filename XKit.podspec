Pod::Spec.new do |s|
  s.name             = 'XKit'
  s.version          = '1.0.0'
  s.summary          = 'XKit is a lightweight and powerful utility library for iOS development.'
  s.swift_version    = '5.0'
  s.description      = <<-DESC
  XKit is a lightweight and powerful utility library for iOS development.
                       DESC
  s.homepage         = 'https://github.com/xueqooy/XKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xueqooy' => 'xue_qooy@163.com' }
  s.source           = { :git => 'https://github.com/xueqooy/XKit.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.source_files = 'XKit/**/*'
  
end
