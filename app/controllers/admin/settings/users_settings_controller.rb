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

module Admin::Settings
  class UsersSettingsController < ::Admin::SettingsController
    menu_item :user_settings

    def show
      @options = {}
      @options[:user_format] = User::USER_FORMATS_STRUCTURE.keys.map { |f| [User.current.name(f), f.to_s] }

      respond_to :html
    end

    def show_local_breadcrumb
      false
    end

    def settings_params
      super.tap do |settings|
        if settings["consent_required"] == "1" && params["toggle_consent_time"] == "1"
          settings["consent_time"] = Time.zone.now.iso8601
        end
      end
    end
  end
end
