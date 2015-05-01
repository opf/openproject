#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

#-- encoding: UTF-8
require File.join(File.dirname(__FILE__), 'test_helper')

class VersionTest < Test::Unit::TestCase
  context 'Versions' do
    setup do
      @user = User.create(name: 'Stephen Richert')
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
      user = User.create(name: 'Stephen Richert')
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
      journal = @user.journals.build(number: 1)
      assert_equal 1, journal.number
      assert_equal true, journal.initial?
    end
  end
end
