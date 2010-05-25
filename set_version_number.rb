#!/usr/bin/env ruby
require 'find'
newversion = `/opt/local/bin/git describe --tags`.match(/(v([0-9]+)(\.([0-9]+)){1,}-([0-9]+))/).to_s.gsub(/[0-9]+$/){|commit| (commit.to_i + 1).to_s}+Time.now.strftime(" %Y-%m-%d")
buffer = File.new('Classes/ASIHTTPRequest.m','r').read
if !buffer.match(/#{Regexp.quote(newversion)}/)
	buffer = buffer.sub(/(NSString \*ASIHTTPRequestVersion = @\")(.*)(";)/,'\1'+newversion+'\3');
	File.open('Classes/ASIHTTPRequest.m','w') {|fw| fw.write(buffer)}
end
