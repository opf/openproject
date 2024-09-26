#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
#++

module Users::FunctionUser
  extend ActiveSupport::Concern

  included do
    validate :validate_unique_function_user, on: :create

    # There should be only one such user in the database
    def validate_unique_function_user
      errors.add :base, "A #{self.class.name} already exists." if self.class.any?
    end

    def available_custom_fields = []

    def logged? = false

    def builtin? = true

    def name(*_args); raise NotImplementedError end

    def mail = nil

    def time_zone; ActiveSupport::TimeZone[Setting.user_default_timezone.presence || "Etc/UTC"] end

    def rss_key = nil

    def destroy = false
  end
end
