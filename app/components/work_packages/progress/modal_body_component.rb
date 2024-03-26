# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

module WorkPackages
  module Progress
    class ModalBodyComponent < ApplicationComponent
      include ApplicationHelper
      include Turbo::FramesHelper
      include OpPrimer::ComponentHelpers

      attr_reader :work_package, :focused_field

      FIELD_MAP = {
        "estimatedTime" => :estimated_hours,
        "remainingTime" => :remaining_hours
      }.freeze

      def initialize(work_package, focused_field:)
        super()

        @work_package = work_package
        @focused_field = map_field(focused_field)
      end

      private

      def map_field(field)
        # Scenarios when a field is not provided occur after a
        # form submission since the last focused element
        # was the submit button. In this case, don't focus on
        # an element by default.
        return nil if field.nil?

        field = FIELD_MAP[field.to_s]

        return field if field.present?

        raise ArgumentError, "The selected field is not one of #{FIELD_MAP.keys.join(', ')}."
      end
    end
  end
end
