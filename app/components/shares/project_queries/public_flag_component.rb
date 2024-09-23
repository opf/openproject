# frozen_string_literal: true

# -- copyright
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
# ++

module Shares
  module ProjectQueries
    class PublicFlagComponent < ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
      BOX_PADDING = 3
      BOX_BORDER_RADIUS = 2
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(strategy:, modal_body_container:)
        super

        @strategy = strategy
        @container = modal_body_container
      end

      private

      attr_reader :strategy, :container

      def toggle_public_flag_link
        toggle_public_project_query_path(strategy.entity)
      end

      def published?
        strategy.entity.public?
      end

      def can_publish?
        User.current.allowed_globally?(:manage_public_project_queries)
      end

      def tooltip_message
        return if can_publish?

        I18n.t("sharing.project_queries.publishing_denied")
      end

      def tooltip_wrapper_classes
        ["d-flex", "flex-column"].tap do |classlist|
          classlist << "tooltip--bottom" unless can_publish?
        end
      end
    end
  end
end
