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

      if Object.const_defined?('RUBY_ENGINE') && ::RUBY_ENGINE == 'jruby'
        # If we have the SQLite3 gem installed, save the old constant
        if Object.const_defined?('Jdbc') && Jdbc::SQLite3.const_defined?('SQLite3')
          sqlite3_version = Jdbc::SQLite3::VERSION
        # else create the module for this test
        else
          module ::Jdbc; module SQLite3; end ;end
          created_module = true
        end
        silence_warnings { ::Jdbc::SQLite3.const_set('VERSION', "1.2.3") }
      else
        # If we run the tests on a newer SQLite3, stub the VERSION constant
        if Object.const_defined?('SQLite3') && SQLite3.const_defined?('SQLITE_VERSION')
          sqlite3_version = SQLite3::SQLITE_VERSION
          silence_warnings { ::SQLite3.const_set('SQLITE_VERSION', "1.2.3") }
        # On an older SQLite3, stub the C-provided sqlite3_libversion method
        elsif %w(SQLite3 Driver Native API).inject(Object){ |m, defined|
          m = (m && m.const_defined?(defined)) ? m.const_get(defined) : false
        }
          SQLite3::Driver::Native::API.stubs('sqlite3_libversion').returns "1.2.3"
        # Fallback if nothing else worked: Stub the old SQLite3 API
        else
          # if we don't have any sqlite3 module, stub the whole module
          module ::SQLite3; module Driver; module Native; module API
            def self.sqlite3_libversion; "1.2.3"; end
          end; end; end; end
          created_module = true
        end
      end

      assert_equal "1.2.3", ChiliProject::Database.version
      assert_equal "1.2.3", ChiliProject::Database.version(true)
    ensure
      # Clean up after us
      if Object.const_defined?('RUBY_ENGINE') && ::RUBY_ENGINE == 'jruby'
        if created_module
          Jdbc.instance_eval{remove_const 'SQLite3' }
        elsif sqlite3_version
          silence_warnings { Jdbc::SQLite3.const_set('VERSION', sqlite3_version) }
        end
      else
        if created_module
          Object.instance_eval{remove_const 'SQLite3' }
        elsif sqlite3_version
          silence_warnings { SQLite3.const_set('SQLITE_VERSION', sqlite3_version) }
        end
      end
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
