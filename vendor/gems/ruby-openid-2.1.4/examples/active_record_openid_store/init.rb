# might using the ruby-openid gem
begin
  require 'rubygems'
rescue LoadError
  nil
end
require 'openid'
require 'openid_ar_store'
