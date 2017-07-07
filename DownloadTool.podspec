Pod::Spec.new do |s|
  s.name             = 'DownloadTool'
  s.version          = '0.1.0'
  s.summary          = 'concurrent download tool.'
  s.description      = <<-DESC
       concurrent download tool,downloading
                       DESC

  s.homepage         = 'http://www.jianshu.com/p/0282ad18e2ef'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Anny-github' => 'wenshanshan1991@163.con' }
  s.source           = { :git => 'https://github.com/Anny-github/DownloadTool.git', :tag => '0.0.1'}
  s.ios.deployment_target = '8.0'

  s.source_files = 'DownloadTool/Classes/**/*'

  # s.resource_bundles = {
  #   'DownloadTool' => ['DownloadTool/Assets/*.png']
  # }

  s.public_header_files = 'DownloadTool/Classes/**/*.h'
  s.frameworks = 'UIKit'
 ## s.dependency 'AFNetworking', '~> 2.3'

end
