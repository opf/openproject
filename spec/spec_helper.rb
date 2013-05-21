require 'spec_helper'

# prevent case where we are using rubygems and test-unit 2.x is installed
begin
  require 'rubygems'
  gem "test-unit", "~> 1.2.3"
rescue LoadError
end


def l(*args)
  I18n.t(*args)
end

# not sure whether these are required - commenting them out for now
#  - mfrister
# require File.join(RAILS_ROOT, "test", "object_daddy_helpers.rb")
# Dir.glob(File.expand_path("#{__FILE__}/../../../redmine_costs/test/exemplars/*.rb")) { |e| require e }
# Dir.glob(File.expand_path("#{__FILE__}/../models/helpers/*_helper.rb")) { |e| require e }

def login_user(user)
  @controller.send(:logged_user=, user)
  @controller.stub!(:find_current_user).and_return(user)
end

def is_member(project, user, permissions = [])
  role = Factory.create(:role, :permissions => permissions)

  Factory.create(:member, :project => project,
                          :principal => user,
                          :roles => [role])
end
