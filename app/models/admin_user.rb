# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
# ++

class AdminUser < User
  validate :validate_unique_admin_user, on: :create

  # There should be only one DeletedUser in the database
  def validate_unique_admin_user
    errors.add :base, 'An AdminUser already exists.' if AdminUser.any?
  end

  def self.first
    super || create(admin: true)
  end

  # Overrides a few properties
  def logged?; false end

  def builtin?; true end

  def name(*_args); 'Builtin admin' end

  def mail; nil end

  def time_zone; nil end

  def rss_key; nil end

  def destroy; false end
end
