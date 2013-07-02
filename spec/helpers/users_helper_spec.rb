#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe UsersHelper do
  include UsersHelper

  describe 'full_user_status' do
    def build_user(status, blocked)
      user = FactoryGirl.build(:user)
      user.stub!(:status).and_return(User::STATUSES[status])
      user.stub!(:failed_too_many_recent_login_attempts?).and_return(blocked)
      user.stub!(:failed_login_count).and_return(3)
      user
    end

    TEST_CASES = {
      [:active, false] => 'active',
      [:active, true] => 'blocked (3 failed login attempts)',
      [:locked, false] => 'locked',
      [:locked, true] => 'locked and blocked (3 failed login attempts)',
      [:registered, false] => 'registered',
      [:registered, true] => 'registered and blocked (3 failed login attempts)'
    }

    TEST_CASES.each do |(status, blocked), expectation|
      describe "with status #{status} and blocked #{blocked}" do
        before do
          user = build_user(status, blocked)
          @status = full_user_status(user)
        end

        it "should return #{expectation}" do
          @status.should == expectation
        end
      end
    end
  end
end
