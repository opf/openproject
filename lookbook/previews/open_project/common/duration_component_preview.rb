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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class DurationComponentPreview < Lookbook::Preview
      # @param duration number
      # @param type select { choices: [seconds, minutes, hours, days, weeks, months, years] }
      # @param separator text
      # @param abbreviated toggle
      def default(duration: 1234, type: :minutes, separator: ", ", abbreviated: false)
        render OpenProject::Common::DurationComponent.new(duration, type, separator:, abbreviated:)
      end

      def system_arguments
        render OpenProject::Common::DurationComponent.new(3625, :seconds, color: :subtle)
      end

      def iso8601
        render OpenProject::Common::DurationComponent.new("P3DT12H5M", :seconds, color: :subtle)
      end

      def plain_text
        render_with_template
      end
    end
  end
end
