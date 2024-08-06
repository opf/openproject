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

module Storages
  module Admin
    module SidePanel
      class HealthStatusComponent < ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
        include ApplicationHelper
        include OpTurbo::Streamable
        include OpPrimer::ComponentHelpers

        def initialize(storage:)
          super(storage)
          @storage = storage
        end

        private

        def health_status_indicator
          case @storage.health_status
          when "healthy"
            { scheme: :success, label: I18n.t("storages.health.label_healthy") }
          when "unhealthy"
            { scheme: :danger, label: I18n.t("storages.health.label_error") }
          else
            { scheme: :attention, label: I18n.t("storages.health.label_pending") }
          end
        end

        # This method returns the health identifier, description and the time since when the error occurs in a
        # formatted manner. e.g. "Not found: Outbound request destination not found since 12/07/2023 03:45 PM"
        def formatted_health_reason
          "#{@storage.health_reason_identifier.tr('_', ' ').strip.capitalize}: #{@storage.health_reason_description} " +
            I18n.t("storages.health.since", datetime: helpers.format_time(@storage.health_changed_at))
        end

        def validation_result_placeholder
          ConnectionValidation.new(type: :none,
                                   error_code: :none,
                                   timestamp: Time.current,
                                   description: I18n.t("storages.health.connection_validation.placeholder"))
        end
      end
    end
  end
end
