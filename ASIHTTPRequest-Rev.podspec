Pod::Spec.new do |s|
  s.name         = "ASIHTTPRequest-Rev"
  s.version      = "2.0.0"
  s.summary      = "Fork for the ASIHTTPRequest,fixed input stream leaks in iOS7,fixed persistent connections error bug,SSL issue"
  s.homepage     = "https://github.com/John1261/asi-http-request"
  s.license      = "MIT"
  s.author       = { 'John' => 'john' }
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/John1261/asi-http-request.git", :tag => "v2.0.0" }
  s.source_files  = "Classes", "Classes/*.{h,m}"
  s.library   = "z.1"
  s.frameworks = "CFNetwork","SystemConfiguration","MobileCoreServices","CoreGraphics"
  s.requires_arc = false
  s.dependency 'Reachability', '~> 3.2'

end