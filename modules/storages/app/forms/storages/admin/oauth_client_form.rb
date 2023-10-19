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

module Storages::Admin
  class OAuthClientForm < ApplicationForm
    form do |oauth_client_form|
      oauth_client_form.text_field(name: :client_id,
                                   label: label_client_id,
                                   required: true)

      oauth_client_form.text_field(name: :client_secret,
                                   label: label_client_secret,
                                   required: true)

      oauth_client_form.group(layout: :horizontal) do |button_group|
        button_group.submit(name: :submit,
                            scheme: :primary,
                            label: I18n.t('storages.buttons.save_and_continue'))
        button_group.button(name: :cancel,
                            scheme: :default,
                            tag: :a,
                            href: Rails.application.routes.url_helpers.edit_admin_settings_storage_path(@storage),
                            label: I18n.t('button_cancel'))
      end
    end

    def initialize(storage: false)
      super()
      @storage = storage
    end

    private

    def label_client_id
      [label_provider_name, I18n.t('storages.label_oauth_client_id')].join(' ')
    end

    def label_client_secret
      [label_provider_name, I18n.t('storages.label_oauth_client_secret')].join(' ')
    end

    def label_provider_name
      I18n.t("storages.provider_types.#{@storage.short_provider_type}.name")
    end
  end
end
