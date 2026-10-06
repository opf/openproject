# frozen_string_literal: true

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
  class PagesController < ::Admin::SettingsController
    helper_method :settings_page

    current_menu_item do |controller|
      controller.settings_page.menu_item
    end

    def settings_page
      @settings_page ||= ::Settings::Pages.fetch(params.require(:settings_page))
    end

    protected

    def settings_params
      params
        .expect(settings: [*permit_filters])
        .to_h
        .to_h { |name, value| [name, settings_page.entry(name).parse_param(value)] }
        .with_indifferent_access
    end

    def success_callback(_call)
      flash[:notice] = t(:notice_successful_update)
      redirect_to settings_page_path
    end

    def failure_callback(call)
      flash[:error] = call.message || I18n.t(:notice_internal_server_error)
      redirect_to settings_page_path
    end

    private

    def permit_filters
      restricted_keys = PermittedParams::AllowedSettings.restricted_keys

      settings_page
        .entries
        .reject { restricted_keys.include?(it.name) }
        .map(&:permit_filter)
    end

    def settings_page_path
      public_send(settings_page.path_helper)
    end
  end
end
