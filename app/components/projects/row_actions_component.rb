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

module Projects
  class RowActionsComponent < ApplicationComponent
    def self.menu_id(project)
      "project-#{project.id}-action-menu"
    end

    def initialize(project:, params:)
      super()
      @project = project
      @params = params
    end

    def menu_id
      self.class.menu_id(project)
    end

    def menu_items
      [
        subproject_item,
        settings_item,
        activity_item,
        favorite_item,
        unfavorite_item,
        archive_item,
        unarchive_item,
        copy_item,
        delete_item
      ].compact
    end

    private

    attr_reader :project, :params

    def currently_favorited?
      @currently_favorited ||= Favorite.exists?(user: User.current, favorited_type: "Project", favorited_id: project.id)
    end

    def subproject_item
      return unless User.current.allowed_in_project?(:add_subprojects, project)

      {
        scheme: :default,
        icon: :plus,
        label: I18n.t(:label_subproject_new),
        href: new_project_path(parent_id: project.id)
      }
    end

    def settings_item
      return unless User.current.allowed_in_project?(
        { controller: "/projects/settings/general", action: "show", project_id: project.id },
        project
      )

      {
        scheme: :default,
        icon: :gear,
        label: I18n.t(:label_project_settings),
        href: project_settings_general_path(project),
        data: { turbo: false }
      }
    end

    def activity_item
      return unless User.current.allowed_in_project?(:view_project_activity, project)

      {
        scheme: :default,
        icon: :check,
        label: I18n.t(:label_project_activity),
        href: project_activity_index_path(project, event_types: ["project_details"])
      }
    end

    def favorite_item
      return if currently_favorited? || project.archived?

      {
        scheme: :default,
        icon: "star",
        href: helpers.build_favorite_path(project, format: :html),
        data: { "turbo-method": :post },
        label: I18n.t(:button_favorite),
        aria: { label: I18n.t(:button_favorite) }
      }
    end

    def unfavorite_item
      return unless currently_favorited?
      return if project.archived?

      {
        scheme: :default,
        icon: "star-fill",
        href: helpers.build_favorite_path(project, format: :html),
        data: { "turbo-method": :delete },
        classes: "op-primer--star-icon",
        label: I18n.t(:button_unfavorite),
        aria: { label: I18n.t(:button_unfavorite) }
      }
    end

    def archive_item
      return unless User.current.allowed_in_project?(:archive_project, project) && project.active?

      {
        scheme: :default,
        icon: :lock,
        label: I18n.t(:button_archive),
        href: project_archive_path(project, status: params[:status]),
        data: {
          turbo_method: :post,
          turbo_confirm: I18n.t("project.archive.are_you_sure", name: project.name)
        }
      }
    end

    def unarchive_item
      return unless User.current.admin? && project.archived? && (project.parent.nil? || project.parent.active?)

      {
        scheme: :default,
        icon: :unlock,
        label: I18n.t(:button_unarchive),
        href: project_archive_path(project, status: params[:status]),
        data: { turbo_method: :delete }
      }
    end

    def copy_item
      return unless User.current.allowed_in_project?(:copy_projects, project) && !project.archived?

      {
        scheme: :default,
        icon: :copy,
        label: I18n.t(:button_copy),
        href: copy_project_path(project),
        data: { turbo: false }
      }
    end

    def delete_item
      return unless User.current.admin

      {
        scheme: :danger,
        icon: :trash,
        label: I18n.t(:button_delete),
        href: confirm_destroy_project_path(project),
        data: { turbo_stream: true }
      }
    end
  end
end
