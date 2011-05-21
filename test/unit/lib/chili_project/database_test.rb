# ChiliProject is a project management system.
# Copyright (C) 2010-2011 The ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require File.expand_path('../../../../test_helper', __FILE__)

class ChiliProject::DatabaseTest < ActiveSupport::TestCase
  setup do
    ChiliProject::Database.stubs(:adapter_name).returns "SQLite"
  end

  should "return the correct identifier" do
    assert_equal :sqlite, ChiliProject::Database.name
  end

  should "be able to use the helper methods" do
    assert_equal false, ChiliProject::Database.mysql?
    assert_equal false, ChiliProject::Database.postgresql?
    assert_equal true, ChiliProject::Database.sqlite?
  end

  should "return a version string for SQLite3" do
    begin
      ChiliProject::Database.stubs(:adapter_name).returns "SQLite"

      # if we run the tests on sqlite, just stub the version method
      if Object.const_defined? 'SQLite3'
        SQLite3::Driver::Native::API.stubs(:sqlite3_libversion).returns "1.2.3"
      else
        # if we don't have any sqlite3 module, stub the whole module
        module ::SQLite3; module Driver; module Native; module API
          def self.sqlite3_libversion; "1.2.3"; end
        end; end; end; end
        created_stub = true
      end

      assert_equal "1.2.3", ChiliProject::Database.version
      assert_equal "1.2.3", ChiliProject::Database.version(true)
    ensure
      # Clean up after us
      Object.instance_eval{remove_const :SQLite3 } if created_stub
    end
  end

  should "return a version string for PostgreSQL" do
    ChiliProject::Database.stubs(:adapter_name).returns "PostgreSQL"
    raw_version = "PostgreSQL 8.3.11 on x86_64-pc-linux-gnu, compiled by GCC gcc-4.3.real (Debian 4.3.2-1.1) 4.3.2"
    ActiveRecord::Base.connection.stubs(:select_value).returns raw_version

    assert_equal "8.3.11", ChiliProject::Database.version
    assert_equal raw_version, ChiliProject::Database.version(true)
  end

  should "return a version string for MySQL" do
    ChiliProject::Database.stubs(:adapter_name).returns "MySQL"
    ActiveRecord::Base.connection.stubs(:select_value).returns "5.1.2"

    assert_equal "5.1.2", ChiliProject::Database.version
    assert_equal "5.1.2", ChiliProject::Database.version(true)
  end

end
