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

describe UserPassword do
  let(:old_password) { FactoryGirl.create(:old_user_password) }
  let(:password) { FactoryGirl.create(:old_user_password) }

  describe :expired? do
    it 'should be true for a old password when password expiry is activated' do
      with_settings :password_days_valid => 30 do
        old_password.expired?.should be_true
      end
    end

    it 'should be false when password expiry is enabled and the password was changed recently' do
      with_settings :password_days_valid => 30 do
        password.expired?.should be_true
      end
    end

    it 'should be false for an old password when password expiry is disabled' do
      with_settings :password_days_valid => 0 do
        old_password.expired?.should be_false
      end
    end
  end

end
