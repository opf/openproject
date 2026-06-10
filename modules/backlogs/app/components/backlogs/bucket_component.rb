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
  class BucketComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable
    include CommonHelper

    attr_reader :backlog_bucket, :work_packages, :project, :current_user

    def initialize(backlog_bucket:, project:, work_packages: nil, current_user: User.current)
      super()

      @backlog_bucket = backlog_bucket
      @project = project
      @current_user = current_user
      @work_packages = work_packages || backlog_bucket.displayed_work_packages
                                                      .includes(:status, :type, :assigned_to, :priority, :parent)
    end

    def wrapper_uniq_by
      backlog_bucket.id
    end

    private

    def show_menu?
      backlog_bucket.persisted? && current_user.allowed_in_project?(:create_sprints, project)
    end
  end
end
