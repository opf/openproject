require 'rubygems'
require 'erb'  # to get "h"
require 'active_support'  # to get "returning"
require File.dirname(__FILE__) + '/../lib/gravatar'
include GravatarHelper, GravatarHelper::PublicMethods, ERB::Util

context "gravatar_url with a custom default URL" do
  setup do
    @original_options = DEFAULT_OPTIONS.dup
    DEFAULT_OPTIONS[:default] = "no_avatar.png"
    @url = gravatar_url("somewhere")
  end
  
  specify "should include the \"default\" argument in the result" do
    @url.should match(/&default=no_avatar.png/)
  end
  
  teardown do
    DEFAULT_OPTIONS.merge!(@original_options)
  end
  
end

context "gravatar_url with default settings" do
  setup do
    @url = gravatar_url("somewhere")
  end
  
  specify "should have a nil default URL" do
    DEFAULT_OPTIONS[:default].should be_nil
  end
  
  specify "should not include the \"default\" argument in the result" do
    @url.should_not match(/&default=/)
  end  
  
end