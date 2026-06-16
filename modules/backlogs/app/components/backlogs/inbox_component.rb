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

module Backlogs
  class InboxComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable
    include CommonHelper

    TRUNCATE_MIDDLE = 50

    attr_reader :work_packages, :project, :current_user

    def initialize(work_packages:, project:, current_user: User.current)
      super()

      @work_packages = work_packages
      @project = project
      @current_user = current_user
    end

    def wrapper_uniq_by
      project.id
    end

    def truncated?
      !show_all_backlog && work_packages.size > truncate_threshold
    end

    def visible_work_packages
      return work_packages unless truncated?

      work_packages.first(TRUNCATE_MIDDLE) + work_packages.last(tail_size)
    end

    def show_more_id
      dom_target(:inbox, project, :show_more)
    end

    def show_more_label
      I18n.t("backlogs.inbox_component.show_more", count: omitted_count)
    end

    def last_omitted_id
      work_packages[-(tail_size + 1)]&.id
    end

    private

    def tail_size
      [TRUNCATE_MIDDLE / 5, 1].max
    end

    def truncate_threshold
      TRUNCATE_MIDDLE + (tail_size * 2)
    end

    def omitted_count
      work_packages.size - TRUNCATE_MIDDLE - tail_size
    end
  end
end
