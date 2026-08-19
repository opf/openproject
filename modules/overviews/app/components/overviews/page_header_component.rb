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

module Overviews
  class PageHeaderComponent < ApplicationComponent
    extend Dry::Initializer

    include ApplicationHelper
    include ProjectsHelper
    include Redmine::I18n

    option :project
    option :current_user, default: -> { User.current }

    private

    def breadcrumb_items
      items =
        project.ancestors.visible.map do |ancestor|
          {
            href: project_path(ancestor),
            text: ancestor.name,
            skip_for_mobile: true
          }
        end

      return nil if items.empty?

      items << page_title
      items
    end

    def page_title
      project.name
    end

    def favorited?
      project.favorited_by?(current_user)
    end

    def allowed_to_select_project_custom_fields?
      current_user.allowed_in_project?(:select_project_custom_fields, project)
    end

    def allowed_to_archive?
      current_user.allowed_in_project?(:archive_project, project)
    end

    def allowed_to_export_project_initiation_pdf?
      project.project_creation_wizard_enabled &&
        current_user.allowed_in_project?(:export_projects, project)
    end
  end
end
