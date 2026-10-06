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

module MyDay
  class TaskRowComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(work_package:)
      super()
      @work_package = work_package
    end

    private

    attr_reader :work_package

    def closed? = work_package.closed?

    def check_box_arguments
      {
        name: "work_package_closed_#{work_package.id}",
        label: work_package.subject,
        visually_hide_label: true,
        checked: closed?,
        disabled: true
      }
    end

    def subject_link_arguments
      {
        href: work_package_path(work_package),
        scheme: closed? ? :secondary : :primary,
        font_weight: :semibold,
        style: ("text-decoration: line-through" if closed?)
      }
    end
  end
end
