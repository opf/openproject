begin
  unless defined? RAILS_ROOT
    RAILS_ROOT = ENV["RAILS_ROOT"].dup || File.expand_path(File.dirname(__FILE__) + "../../..")
  end
  require RAILS_ROOT + '/spec/spec_helper'
rescue LoadError => error
  puts <<-EOS

    You need to install rspec in your Redmine project.
    Please execute the following code:
    
      gem install rspec-rails
      script/generate rspec
    
    Or if you have some issues due to symbolic links, try this:
      
      RAILS_ROOT=/path/to/rails rake

  EOS
  raise error
end

require File.join(File.dirname(__FILE__), "..", "init.rb")