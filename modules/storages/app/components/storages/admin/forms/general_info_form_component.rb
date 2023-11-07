# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
#
module Storages::Admin::Forms
  class GeneralInfoFormComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    alias_method :storage, :model

    options form_method: :post,
            submit_button_disabled: false,
            cancel_button_should_break_from_frame: false

    def form_url
      options[:form_url] || default_form_url
    end

    def submit_button_options
      { disabled: submit_button_disabled }
    end

    def cancel_button_options
      { href: cancel_button_path }.tap do |options_hash|
        options_hash[:target] = '_top' if cancel_button_should_break_from_frame
      end
    end

    private

    def default_form_url
      case form_method
      when :get, :post
        Rails.application.routes.url_helpers.admin_settings_storages_path
      when :patch, :put
        Rails.application.routes.url_helpers.admin_settings_storage_path(storage)
      end
    end

    def cancel_button_path
      options[:cancel_button_path] || Rails.application.routes.url_helpers.admin_settings_storages_path
    end
  end
end
