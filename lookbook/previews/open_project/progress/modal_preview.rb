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

module OpenProject
  module Progress
    # @logical_path OpenProject/Progress
    class ModalPreview < Lookbook::Preview
      # @param estimated_hours [Float]
      # @param remaining_hours [Float]
      # @param focused_field select { choices: [~, estimatedTime, remainingTime] }
      def work_based(estimated_hours: nil,
                     remaining_hours: nil,
                     focused_field: nil)
        work_package = FactoryBot.build_stubbed(:work_package,
                                                estimated_hours:,
                                                remaining_hours:)
        render_with_template(locals: { work_package:, focused_field: })
      end

      # @param estimated_hours [Float]
      # @param remaining_hours [Float]
      # @param focused_field select { choices: [~, status_id, estimatedTime] }
      def status_based(estimated_hours: nil,
                       remaining_hours: nil,
                       focused_field: nil)
        work_package = FactoryBot.build_stubbed(:work_package,
                                                estimated_hours:,
                                                remaining_hours:)
        render_with_template(locals: { work_package:, focused_field: })
      end
    end
  end
end
