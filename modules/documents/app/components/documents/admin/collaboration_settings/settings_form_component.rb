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
#

module Documents
  module Admin
    module CollaborationSettings
      class SettingsFormComponent < ApplicationComponent
        include OpPrimer::FormHelpers

        delegate :writable_setting?, to: :helpers

        def initialize(errors: nil)
          super()
          @errors = errors
        end

        def none_writable_settings?
          settings.none? { writable_setting?(it) }
        end

        def some_unwritable_settings?
          settings.any? { !writable_setting?(it) }
        end

        def validation_message_for(attribute)
          if attribute == :collaborative_editing_hocuspocus_url && (@errors&.include?(attribute) || invalid_hocuspocus_url?)
            I18n.t("documents.admin.collaboration_settings.hocuspocus_server_url.invalid_scheme")
          elsif @errors&.include?(attribute)
            @errors.full_messages_for(attribute).to_sentence
          end
        end

        private

        def invalid_hocuspocus_url?
          return false if Setting.collaborative_editing_hocuspocus_url.blank?

          !websocket_url?(Setting.collaborative_editing_hocuspocus_url)
        end

        def websocket_url?(url)
          uri = URI.parse(url)
          uri.is_a?(URI::WS) || uri.is_a?(URI::WSS)
        rescue URI::InvalidURIError
          false
        end

        def settings
          %i[collaborative_editing_hocuspocus_url
             collaborative_editing_hocuspocus_secret]
        end
      end
    end
  end
end
