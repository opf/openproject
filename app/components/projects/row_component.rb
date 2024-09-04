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
  class RowComponent < ::RowComponent
    delegate :favored_project_ids, to: :table

    def project
      model.first
    end

    def level
      model.last
    end

    # Hierarchy cell is just a placeholder
    def hierarchy
      ""
    end

    def favored
      render(Primer::Beta::IconButton.new(
               icon: currently_favored? ? "star-fill" : "star",
               scheme: :invisible,
               mobile_icon: currently_favored? ? "star-fill" : "star",
               size: :medium,
               tag: :a,
               tooltip_direction: :e,
               href: helpers.build_favorite_path(project, format: :html),
               data: { method: currently_favored? ? :delete : :post },
               classes: currently_favored? ? "op-primer--star-icon " : "op-project-row-component--favorite",
               label: currently_favored? ? I18n.t(:button_unfavorite) : I18n.t(:button_favorite),
               aria: { label: currently_favored? ? I18n.t(:button_unfavorite) : I18n.t(:button_favorite) },
               test_selector: "project-list-favorite-button"
             ))
    end

    def currently_favored?
      @currently_favored ||= favored_project_ids.include?(project.id)
    end

    def column_value(column)
      if custom_field_column?(column)
        custom_field_column(column)
      else
        send(column.attribute)
      end
    end

    def custom_field_column(column)
      return nil unless user_can_view_project?

      cf = column.custom_field
      custom_value = project.formatted_custom_value_for(cf)

      if cf.field_format == "text" && custom_value.present?
        render OpenProject::Common::AttributeComponent.new(
          "dialog-#{project.id}-cf-#{cf.id}",
          cf.name,
          custom_value,
          formatted: true
        )
      elsif custom_value.is_a?(Array)
        safe_join(Array(custom_value).compact_blank, ", ")
      else
        custom_value
      end
    end

    def created_at
      helpers.format_date(project.created_at)
    end

    def latest_activity_at
      helpers.format_date(project.latest_activity_at)
    end

    def required_disk_space
      return "" unless project.required_disk_space.to_i > 0

      number_to_human_size(project.required_disk_space, precision: 2)
    end

    def name
      content = content_tag(:i, "", class: "projects-table--hierarchy-icon")

      if project.archived?
        content << " "
        content << content_tag(:span, I18n.t("project.archive.archived"), class: "archived-label")
      end

      content << " "
      content << helpers.link_to_project(project, {}, { data: { turbo: false } }, false)
      content
    end

    def project_status
      return nil unless user_can_view_project?

      content = "".html_safe

      status_code = project.status_code

      if status_code
        classes = helpers.project_status_css_class(status_code)
        content << content_tag(:span, "", class: "project-status--bulb -inline #{classes}")
        content << content_tag(:span, helpers.project_status_name(status_code), class: "project-status--name #{classes}")
      end

      content
    end

    def status_explanation
      return nil unless user_can_view_project?

      if project.status_explanation.present? && project.status_explanation
        render OpenProject::Common::AttributeComponent.new("dialog-#{project.id}-status-explanation",
                                                           I18n.t("activerecord.attributes.project.status_explanation"),
                                                           project.status_explanation)
      end
    end

    def description
      return nil unless user_can_view_project?

      if project.description.present?
        render OpenProject::Common::AttributeComponent.new("dialog-#{project.id}-description",
                                                           I18n.t("activerecord.attributes.project.description"),
                                                           project.description)
      end
    end

    def public
      helpers.checked_image project.public?
    end

    def row_css_class
      classes = %w[basics context-menu--reveal op-project-row-component]
      classes << project_css_classes
      classes << row_css_level_classes

      classes.join(" ")
    end

    def row_css_id
      "project-#{project.id}"
    end

    def row_css_level_classes
      if level > 0
        "idnt idnt-#{level}"
      else
        ""
      end
    end

    def project_css_classes
      s = " project ".html_safe

      s << " root" if project.root?
      s << " child" if project.child?
      s << (project.leaf? ? " leaf" : " parent")

      s
    end

    def column_css_class(column)
      "#{column.attribute} #{additional_css_class(column)}"
    end

    def additional_css_class(column)
      if column.attribute == :name
        "project--hierarchy #{project.archived? ? 'archived' : ''}"
      elsif %i[status_explanation description].include?(column.attribute)
        "project-long-text-container"
      elsif column.attribute == :favored
        "-w-abs-45"
      elsif custom_field_column?(column)
        cf = column.custom_field
        formattable = cf.field_format == "text" ? " project-long-text-container" : ""
        "format-#{cf.field_format}#{formattable}"
      end
    end

    def button_links
      if more_menu_items.empty?
        []
      else
        [action_menu]
      end
    end

    def action_menu
      render(Primer::Alpha::ActionMenu.new(test_selector: "project-list-row--action-menu")) do |menu|
        menu.with_show_button(scheme: :invisible,
                              size: :small,
                              icon: :"kebab-horizontal",
                              "aria-label": t(:label_open_menu),
                              tooltip_direction: :w)
        more_menu_items.each do |action_options|
          action_options => { scheme:, label:, icon:, **button_options }
          menu.with_item(scheme:,
                         label:,
                         test_selector: "project-list-row--action-menu-item",
                         content_arguments: button_options) do |item|
            item.with_leading_visual_icon(icon:) if icon
          end
        end
      end
    end

    def more_menu_items
      @more_menu_items ||= [more_menu_subproject_item,
                            more_menu_settings_item,
                            more_menu_activity_item,
                            more_menu_favorite_item,
                            more_menu_unfavorite_item,
                            more_menu_archive_item,
                            more_menu_unarchive_item,
                            more_menu_copy_item,
                            more_menu_delete_item].compact
    end

    def more_menu_favorite_item
      return if currently_favored?

      {
        scheme: :default,
        icon: "star",
        href: helpers.build_favorite_path(project, format: :html),
        data: { method: :post },
        label: I18n.t(:button_favorite),
        aria: { label: I18n.t(:button_favorite) }
      }
    end

    def more_menu_unfavorite_item
      return unless currently_favored?

      {
        scheme: :default,
        icon: "star-fill",
        size: :medium,
        href: helpers.build_favorite_path(project, format: :html),
        data: { method: :delete },
        classes: "op-primer--star-icon",
        label: I18n.t(:button_unfavorite),
        aria: { label: I18n.t(:button_unfavorite) }
      }
    end

    def more_menu_subproject_item
      if User.current.allowed_in_project?(:add_subprojects, project)
        {
          scheme: :default,
          icon: :plus,
          label: I18n.t(:label_subproject_new),
          href: new_project_path(parent_id: project.id)
        }
      end
    end

    def more_menu_settings_item
      if User.current.allowed_in_project?({ controller: "/projects/settings/general", action: "show", project_id: project.id },
                                          project)
        {
          scheme: :default,
          icon: :gear,
          label: I18n.t(:label_project_settings),
          href: project_settings_general_path(project)
        }
      end
    end

    def more_menu_activity_item
      if User.current.allowed_in_project?(:view_project_activity, project)
        {
          scheme: :default,
          icon: :check,
          label: I18n.t(:label_project_activity),
          href: project_activity_index_path(project, event_types: ["project_attributes"])
        }
      end
    end

    def more_menu_archive_item
      if User.current.allowed_in_project?(:archive_project, project) && project.active?
        {
          scheme: :default,
          icon: :lock,
          label: I18n.t(:button_archive),
          href: project_archive_path(project, status: params[:status]),
          data: {
            confirm: t("project.archive.are_you_sure", name: project.name),
            method: :post
          }
        }
      end
    end

    def more_menu_unarchive_item
      if User.current.admin? && project.archived? && (project.parent.nil? || project.parent.active?)
        {
          scheme: :default,
          icon: :unlock,
          label: I18n.t(:button_unarchive),
          href: project_archive_path(project, status: params[:status]),
          data: { method: :delete }
        }
      end
    end

    def more_menu_copy_item
      if User.current.allowed_in_project?(:copy_projects, project) && !project.archived?
        {
          scheme: :default,
          icon: :copy,
          label: I18n.t(:button_copy),
          href: copy_project_path(project),
          data: { turbo: false }
        }
      end
    end

    def more_menu_delete_item
      if User.current.admin
        {
          scheme: :danger,
          icon: :trash,
          label: I18n.t(:button_delete),
          href: confirm_destroy_project_path(project)
        }
      end
    end

    def user_can_view_project?
      User.current.allowed_in_project?(:view_project_attributes, project)
    end

    def custom_field_column?(column)
      column.is_a?(::Queries::Projects::Selects::CustomField)
    end
  end
end
