#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
require File.expand_path('../../../../test_helper', __FILE__)

class ChiliProject::DatabaseTest < ActiveSupport::TestCase
  setup do
    ChiliProject::Database.stub(:adapter_name).and_return 'PostgresQL'
  end

  should 'return the correct identifier' do
    assert_equal :postgresql, ChiliProject::Database.name
  end

  should 'be able to use the helper methods' do
    assert_equal false, ChiliProject::Database.mysql?
    assert_equal true, ChiliProject::Database.postgresql?
  end

  should 'return a version string for PostgreSQL' do
    ChiliProject::Database.stub(:adapter_name).and_return 'PostgreSQL'
    raw_version = 'PostgreSQL 8.3.11 on x86_64-pc-linux-gnu, compiled by GCC gcc-4.3.real (Debian 4.3.2-1.1) 4.3.2'
    ActiveRecord::Base.connection.stub(:select_value).and_return raw_version

    assert_equal '8.3.11', ChiliProject::Database.version
    assert_equal raw_version, ChiliProject::Database.version(true)
  end

  should 'return a version string for MySQL' do
    ChiliProject::Database.stub(:adapter_name).and_return 'MySQL'
    ActiveRecord::Base.connection.stub(:select_value).and_return '5.1.2'

    assert_equal '5.1.2', ChiliProject::Database.version
    assert_equal '5.1.2', ChiliProject::Database.version(true)
  end
end
