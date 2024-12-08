#
# Be sure to run `pod lib lint XKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XKit'
  s.version          = '0.1.0'
  s.summary          = 'A short description of XKit.'
  s.swift_version    = '5.0'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/xueqooy/XKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xue-nd' => 'xue_qooy@163.com' }
  s.source           = { :git => 'https://github.com/xueqooy/XKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.source_files = 'XKit/**/*'
  
end
