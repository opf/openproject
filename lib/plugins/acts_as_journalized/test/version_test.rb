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

class VersionTest < Test::Unit::TestCase
  context 'Versions' do
    setup do
      @user = User.create(:name => 'Stephen Richert')
      @user.update_attribute(:name, 'Steve Jobs')
      @user.update_attribute(:last_name, 'Richert')
      @first_journal, @last_journal = @user.journals.first, @user.journals.last
    end

    should 'be comparable to another journal based on journal number' do
      assert @first_journal == @first_journal
      assert @last_journal == @last_journal
      assert @first_journal != @last_journal
      assert @last_journal != @first_journal
      assert @first_journal < @last_journal
      assert @last_journal > @first_journal
      assert @first_journal <= @last_journal
      assert @last_journal >= @first_journal
    end

    should "not equal a separate model's journal with the same number" do
      user = User.create(:name => 'Stephen Richert')
      user.update_attribute(:name, 'Steve Jobs')
      user.update_attribute(:last_name, 'Richert')
      first_journal, last_journal = user.journals.first, user.journals.last
      assert_not_equal @first_journal, first_journal
      assert_not_equal @last_journal, last_journal
    end

    should 'default to ordering by number when finding through association' do
      order = @user.journals.send(:scope, :find)[:order]
      assert_equal 'journals.number ASC', order
    end

    should 'return true for the "initial?" method when the journal number is 1' do
      journal = @user.journals.build(:number => 1)
      assert_equal 1, journal.number
      assert_equal true, journal.initial?
    end
  end
end
