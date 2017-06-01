#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class TaggingTest < Test::Unit::TestCase
  context 'Tagging a journal' do
    setup do
      @user = User.create(name: 'Steve Richert')
      @user.update_attribute(:last_name, 'Jobs')
    end

    should "update the journal record's tag column" do
      tag_name = 'TAG'
      last_journal = @user.journals.last
      assert_not_equal tag_name, last_journal.tag
      @user.tag_journal(tag_name)
      assert_equal tag_name, last_journal.reload.tag
    end

    should 'create a journal record for an initial journal' do
      @user.revert_to(1)
      assert_nil @user.journals.at(1)
      @user.tag_journal('TAG')
      assert_not_nil @user.journals.at(1)
    end
  end

  context 'A tagged journal' do
    setup do
      user = User.create(name: 'Steve Richert')
      user.update_attribute(:last_name, 'Jobs')
      user.tag_journal('TAG')
      @journal = user.journals.last
    end

    should 'return true for the "tagged?" method' do
      assert @journal.respond_to?(:tagged?)
      assert_equal true, @journal.tagged?
    end
  end
end
