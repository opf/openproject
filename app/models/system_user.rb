#-- encoding: UTF-8
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

#
# User for tasks like migrations
#

class SystemUser < User
  module DisableCustomizable
    def self.included(base)
      # Prevent save_custom_field_values method from running.
      # I am not sure why this is necessary so this can be considered a hack.
      #
      # The symptoms are, that saving User.system, which will happen when calling
      # User.system.run_given, from inside a migration fails.
      #
      # The callback sends self.custom_values which leads to an error
      # stating that no column "name", "default_value" or "possible_values"
      # exists in the db. It is correct that such a field does not exist, as those are
      # translated attributes so that they are to be found in custom_field_translations.
      #
      # It seems to me that CustomField is not correctly instrumented by globalize3 which
      # should delegate attribute assignment to any such column to the translation table.

      base.skip_callback :save, :after, :save_custom_field_values
    end

    def available_custom_fields
      []
    end
  end

  include DisableCustomizable

  validate :validate_unique_system_user, on: :create

  # There should be only one SystemUser in the database
  def validate_unique_system_user
    errors.add :base, 'A SystemUser already exists.' if SystemUser.any?
  end

  # Overrides a few properties
  def logged?; false end

  def name(*_args); 'System' end

  def mail; nil end

  def time_zone; nil end

  def rss_key; nil end

  def destroy; false end

  def grant_privileges
    self.admin = true
    self.status = STATUSES[:builtin]
  end

  def remove_privileges
    self.admin = false
    self.status = STATUSES[:locked]
  end

  def run_given(&_block)
    if block_given?
      grant_privileges
      old_user = User.current
      User.current = self

      begin
        yield
      ensure
        remove_privileges
        User.current = old_user
      end
    else
      raise 'no block given'
    end
  end
end
