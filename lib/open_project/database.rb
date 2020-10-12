#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++
require 'semantic'

module OpenProject
  # This module provides some information about the currently used database
  # adapter. It can be used to write code specific to certain database
  # vendors which, while not not encouraged, is sometimes necessary due to
  # syntax differences.

  module Database
    DB_VALUE_FALSE = 'f'.freeze
    DB_VALUE_TRUE = 't'.freeze

    class InsufficientVersionError < StandardError; end
    class UnsupportedDatabaseError < StandardError; end

    # This method returns a hash which maps the identifier of the supported
    # adapter to a regex matching the adapter_name.
    def self.supported_adapters
      @adapters ||= begin
        {
          postgresql: /postgres/i
        }
      end
    end

    ##
    # Get the database system requirements
    def self.required_version
      {
        numeric: 90500, # PG_VERSION_NUM
        string: '9.5.0'
      }
    end

    ##
    # Check pending database migrations
    # and cache the result for up to one hour
    def self.migrations_pending?(ensure_fresh: false)
      cache_key = OpenProject::Cache::CacheKey.key('database_migrations')
      cached_result = Rails.cache.read(cache_key)

      # Ensure cache is busted if result is positive or unset
      # and the value was cached
      if ensure_fresh || cached_result != false
        fresh_result = connection.migration_context.needs_migration?
        Rails.cache.write(cache_key, expires_in: 1.hour)
        return fresh_result
      end

      false
    end

    ##
    # Check the database for
    # * being postgresql
    # * version compatibility
    #
    # Raises an +UnsupportedDatabaseError+ when the version is incompatible
    # Raises an +InsufficientVersionError+ when the version is incompatible
    def self.check!
      if !postgresql?
        message = "Database server is not PostgreSql. " \
                  "As OpenProject uses non standard ANSI-SQL for performance optimizations, using a different DBMS will " \
                  "break and is thus prevented."

        if adapter_name.match?(/mysql/i)
          message << " As MySql used to be supported, there is a migration script to ease the transition " \
                     "(https://www.openproject.org/deprecating-mysql-support/)."
        end

        raise UnsupportedDatabaseError.new message
      elsif !version_matches?
        current = version

        message = "Database server version mismatch: Required version is #{required_version[:string]}, " \
                  "but current version is #{current}"

        raise InsufficientVersionError.new message
      end
    end

    ##
    # Return +true+ if the required version is matched by the current connection.
    def self.version_matches?
      numeric_version >= required_version[:numeric]
    end

    # Get the raw name of the currently used database adapter.
    # This string is set by the used adapter gem.
    def self.adapter_name(connection = self.connection)
      connection.adapter_name
    end

    # Get the AR base connection object handle
    # will open a db connection implicitly
    def self.connection
      ActiveRecord::Base.connection
    end

    # returns the identifier of the specified connection
    # (defaults to ActiveRecord::Base.connection)
    def self.name(connection = self.connection)
      supported_adapters.find(proc { [:unknown, //] }) do |_adapter, regex|
        adapter_name(connection) =~ regex
      end[0]
    end

    # Provide helper methods to quickly check the database type
    # OpenProject::Database.postgresql? returns true, if we have a postgresql DB
    # Also allows specification of a connection e.g.
    # OpenProject::Database.postgresql?(my_connection)
    supported_adapters.keys.each do |adapter|
      (class << self; self; end).class_eval do
        define_method(:"#{adapter.to_s}?") do |connection = self.connection|
          send(:name, connection) == adapter
        end
      end
    end

    def self.mysql?(_arg = nil)
      message = ".mysql? is no longer supported and will always return false. Remove the call."
      ActiveSupport::Deprecation.warn message, caller
      false
    end

    # Return the version of the underlying database engine.
    # Set the +raw+ argument to true to return the unmangled string
    # from the database.
    def self.version(raw = false)
      @version ||= ActiveRecord::Base.connection.select_value('SELECT version()')

      raw ? @version : @version.match(/\APostgreSQL ([\d\.]+)/i)[1]
    end

    def self.numeric_version
      ActiveRecord::Base.connection.select_value('SHOW server_version_num;').to_i
    end

    # Return if the version of the underlying database engine is capable of TSVECTOR features, needed for full-text
    # search.
    def self.allows_tsv?
      version_matches?
    end
  end
end
