#-- encoding: UTF-8
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

#
# User for tasks like migrations
#

class SystemUser < User
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
