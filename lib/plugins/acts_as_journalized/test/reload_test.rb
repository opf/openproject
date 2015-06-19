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

class ReloadTest < Test::Unit::TestCase
  context 'Reloading a reverted model' do
    setup do
      @user = User.create(name: 'Steve Richert')
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
