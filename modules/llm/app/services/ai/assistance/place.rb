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

module AI
  module Assistance
    # Where the user uses AI Assistance: a work package, a project, or a page without
    # either. It decides the permission, the skills on offer, the chats and the context.
    class Place
      attr_reader :work_package, :project

      # From the work_package_id or project_id of a request. Nil when the user cannot see it.
      def self.from_params(params, user:)
        if params[:work_package_id].present?
          work_package = WorkPackage.visible(user).find_by_display_id(params[:work_package_id])
          work_package && new(work_package:)
        elsif params[:project_id].present?
          project = find_project(params[:project_id].to_s, user)
          project && new(project:)
        else
          new
        end
      end

      def self.find_project(id, user)
        projects = Project.visible(user)
        projects.find_by(identifier: id) || (projects.find_by(id:) if id.match?(/\A\d+\z/))
      end

      def initialize(work_package: nil, project: nil)
        @work_package = work_package
        @project = project || work_package&.project
      end

      def work_package? = work_package.present?

      def visible?(user)
        if work_package then WorkPackage.visible(user).exists?(id: work_package.id)
        elsif project then project.visible?(user)
        else true
        end
      end

      def allowed?(user)
        if work_package then user.allowed_in_work_package?(:use_ai_assistance, work_package)
        elsif project then user.allowed_in_project?(:use_ai_assistance, project)
        else user.allowed_in_any_project?(:use_ai_assistance)
        end
      end

      # The query parameters of the AI Assistance routes.
      def url_params
        if work_package then { work_package_id: work_package.id }
        elsif project then { project_id: project.identifier }
        else {}
        end
      end

      # "#2" for a work package, else the project's name, else nil.
      def label
        work_package&.formatted_id || project&.name
      end

      # Where a plain page request goes back to.
      def page_path
        url_helpers = Rails.application.routes.url_helpers
        if work_package then url_helpers.work_package_path(work_package)
        elsif project then url_helpers.project_path(project)
        else url_helpers.home_path
        end
      end

      def ==(other)
        other.is_a?(Place) && other.work_package == work_package && other.project == project
      end
    end
  end
end
