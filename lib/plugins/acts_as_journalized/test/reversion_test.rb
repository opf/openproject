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

class RejournalTest < Test::Unit::TestCase
  context 'A model rejournal' do
    setup do
      @user, @attributes, @times = User.new, {}, {}
      names = ['Steve Richert', 'Stephen Richert', 'Stephen Jobs', 'Steve Jobs']
      time = names.size.hours.ago
      names.each do |name|
        @user.update_attribute(:name, name)
        @attributes[@user.journal] = @user.attributes
        time += 1.hour
        if last_journal = @user.journals.last
          last_journal.update_attribute(:created_at, time)
        end
        @times[@user.journal] = time
      end
      @user.reload.journals.reload
      @first_journal, @last_journal = @attributes.keys.min, @attributes.keys.max
    end

    should 'return the new journal number' do
      new_journal = @user.revert_to(@first_journal)
      assert_equal @first_journal, new_journal
    end

    should 'change the journal number when saved' do
      current_journal = @user.journal
      @user.revert_to!(@first_journal)
      assert_not_equal current_journal, @user.journal
    end

    should 'do nothing for a invalid argument' do
      current_journal = @user.journal
      [nil, :bogus, 'bogus', (1..2)].each do |invalid|
        @user.revert_to(invalid)
        assert_equal current_journal, @user.journal
      end
    end

    should 'be able to target a journal number' do
      @user.revert_to(1)
      assert 1, @user.journal
    end

    should 'be able to target a date and time' do
      @times.each do |journal, time|
        @user.revert_to(time + 1.second)
        assert_equal journal, @user.journal
      end
    end

    should 'be able to target a journal object' do
      @user.journals.each do |journal|
        @user.revert_to(journal)
        assert_equal journal.number, @user.journal
      end
    end

    should "correctly roll back the model's attributes" do
      timestamps = %w(created_at created_on updated_at updated_on)
      @attributes.each do |journal, attributes|
        @user.revert_to!(journal)
        assert_equal attributes.except(*timestamps), @user.attributes.except(*timestamps)
      end
    end
  end
end
