Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name             = 'Enlighten'
  s.version          = '1.0'
  s.summary          = '💡 An integrated spotlight-based onboarding and help library for macOS, written in Swift.'
  s.homepage         = 'https://github.com/chriszielinski/Enlighten'
  s.screenshots     = 'https://raw.githubusercontent.com/chriszielinski/Enlighten/master/readme-assets/gifs/enlighten.gif'
  s.documentation_url = 'https://chriszielinski.github.io/Enlighten/'


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license          = { :type => 'MIT', :file => 'LICENSE' }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author           = { 'chriszielinski' => 'chrisz@berkeley.edu' }
  s.social_media_url = 'http://twitter.com/mightbesuperman'


  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.platform = :osx, '10.12'


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source           = { :git => 'https://github.com/chriszielinski/Enlighten.git', :tag => s.version.to_s }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files     = 'Source/**/*.swift'
  s.swift_version    = "4.2"

  # ――― Dependencies ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.dependency 'Down'

end