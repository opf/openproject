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

module OpenProject::WorkPackages
  # @logical_path OpenProject/WorkPackages
  class InfoLineComponentPreview < ViewComponent::Preview
    # See the [component documentation](/lookbook/pages/components/work_package_info_line) for more details.
    # @param show_project [Boolean]
    # @param show_subject [Boolean]
    # @param show_status [Boolean]
    # @param font_size [Symbol] select [small, normal]
    # @param status_scheme select [default, secondary]
    # @param wrap [Boolean]
    def playground(show_project: false, show_subject: false, show_status: true, font_size: :small, status_scheme: :default,
                   wrap: true)
      render(WorkPackages::InfoLineComponent.new(work_package: WorkPackage.visible.first,
                                                 show_project:,
                                                 show_subject:,
                                                 show_status:,
                                                 status_scheme:,
                                                 font_size:,
                                                 wrap:))
    end
  end
end
