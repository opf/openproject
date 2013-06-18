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

#-- encoding: UTF-8
require File.join(File.dirname(__FILE__), 'test_helper')

class ReloadTest < Test::Unit::TestCase
  context 'Reloading a reverted model' do
    setup do
      @user = User.create(:name => 'Steve Richert')
      first_version = @user.version
      @user.update_attribute(:last_name, 'Jobs')
      @last_version = @user.version
      @user.revert_to(first_version)
    end

    should 'reset the journal number to the most recent journal' do
      assert_not_equal @last_journal, @user.journal
      @user.reload
      assert_equal @last_journal, @user.journal
    end
  end
end
