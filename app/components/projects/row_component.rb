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
    include CalculatedValues::ErrorsHelper

    delegate :identifier, to: :project
    delegate :favorited_project_ids,
             :project_phase_by_definition,
             to: :table

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

    def favorited # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
      return nil unless User.current.logged?
      return nil if project.archived?

      render(Primer::Beta::IconButton.new(
               icon: currently_favorited? ? "star-fill" : "star",
               scheme: :invisible,
               mobile_icon: currently_favorited? ? "star-fill" : "star",
               size: :medium,
               tag: :a,
               tooltip_direction: :e,
               href: helpers.build_favorite_path(project, format: :html),
               data: { turbo_method: currently_favorited? ? :delete : :post },
               classes: currently_favorited? ? "op-primer--star-icon " : "op-project-row-component--favorite",
               label: currently_favorited? ? I18n.t(:button_unfavorite) : I18n.t(:button_favorite),
               aria: { label: currently_favorited? ? I18n.t(:button_unfavorite) : I18n.t(:button_favorite) },
               test_selector: "project-list-favorite-button"
             ))
    end

    def currently_favorited?
      @currently_favorited ||= favorited_project_ids.include?(project.id)
    end

    def column_value(column)
      return custom_field_column(column) if custom_field_column?(column)
      return custom_comment_column(column) if custom_comment_column?(column)
      return project_phase_column(column) if project_phase_column?(column)

      send(column.attribute)
    end

    def custom_field_column(column)
      return nil unless user_can_view_project_attributes?

      super
    end

    def render_calculated_value(custom_field, custom_value)
      if (error = custom_field.first_calculation_error(project))
        render(Primer::Alpha::Dialog.new(title: I18n.t("calculated_values.error_dialog.title"),
                                         data: {
                                           test_selector: "calculated-value-error-dialog-#{custom_field.id}"
                                         })) do |dialog|
          dialog.with_show_button(icon: "alert-fill",
                                  "aria-label": I18n.t("calculated_values.error_dialog.title"),
                                  data: { test_selector: "calculated-value-error-btn-#{custom_field.id}" },
                                  scheme: :invisible)
          dialog.with_body { calculated_value_error_msg(error) }
        end
      else
        custom_value
      end
    end

    def custom_comment_column(column)
      return nil unless user_can_view_project_attributes?

      cf = column.custom_field
      comment = cf.comment_for(project)&.text
      return nil if comment.blank?

      render OpenProject::Common::AttributeComponent.new(
        "dialog-#{project.id}-cfc-#{cf.id}",
        column.caption,
        comment,
        format: false
      )
    end

    def project_phase_column(column)
      return nil unless user_can_view_project_phases?

      phase = project_phase_by_definition(column.project_phase_definition, project)

      return nil if phase.blank?

      render Projects::PhaseComponent.new(phase:)
    end

    def created_at
      helpers.format_date(project.created_at)
    end

    def latest_activity_at
      helpers.format_date(project.latest_activity_at)
    end

    def updated_at
      helpers.format_date(project.updated_at)
    end

    def required_disk_space
      return "" unless project.required_disk_space.to_i > 0

      number_to_human_size(project.required_disk_space, precision: 2)
    end

    def id
      project.id.to_s
    end

    def name
      content = [
        hierarchy_icon,
        name_link_section,
        archived_label,
        workspace_type_badge
      ].compact_blank

      content_tag(:div, safe_join(content), class: "projects-table--name")
    end

    def hierarchy_icon
      content_tag(:i, "", class: "projects-table--hierarchy-icon")
    end

    def name_link_section
      content_tag(:span, class: "projects-table--name-text") do
        helpers.link_to_project(project, {}, { data: { turbo: false } }, false)
      end
    end

    def workspace_type_badge
      # Only show icon and type for non-project workspaces
      return unless project.workspace_type.in?(["portfolio", "program"])

      render(Primer::Beta::Text.new(classes: "projects-table--name-description")) do
        icon = render(Primer::Beta::Octicon.new(
                        icon: helpers.workspace_icon(project.workspace_type),
                        size: :xsmall
                      ))

        safe_join([icon, " ", I18n.t(:"label_#{project.workspace_type}")])
      end
    end

    def archived_label
      return unless project.archived?

      content_tag(:span, "(#{I18n.t('project.archive.archived')})", class: "archived-label")
    end

    def project_status
      return nil unless user_can_view_project_attributes?

      status_code = project.status_code
      if status_code
        classes = helpers.project_status_css_class(status_code)

        capture do
          concat content_tag(:span, "", class: "project-status--bulb -inline #{classes}")
          concat content_tag(:span, helpers.project_status_name(status_code), class: "project-status--name #{classes}")
        end
      end
    end

    def status_explanation
      return nil unless user_can_view_project_attributes?

      if project.status_explanation.present? && project.status_explanation
        render OpenProject::Common::AttributeComponent.new("dialog-#{project.id}-status-explanation",
                                                           I18n.t("activerecord.attributes.project.status_explanation"),
                                                           project.status_explanation)
      end
    end

    def description
      return nil unless user_can_view_project_attributes?

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
      classes += project_css_classes
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
      output = ["project"]

      output << "root" if project.root?
      output << "child" if project.child?
      output << (project.leaf? ? "leaf" : "parent")

      output
    end

    def column_css_class(column)
      "#{column.attribute} #{additional_css_class(column)}"
    end

    def additional_css_class(column)
      if column.attribute == :name
        "project--hierarchy #{'archived' if project.archived?}"
      elsif column.attribute == :favorited
        "-w-abs-45"
      elsif custom_field_column?(column)
        "format-#{column.custom_field.field_format}"
      end
    end

    def button_links
      # The action menu is currently only relevant for logged in users
      # short-circuiting this call for anonymous users, which often hit our projects page.
      return [] if !User.current.logged? || menu_items&.empty?

      if menu_items
        [action_menu(items: menu_items)]
      else
        [action_menu(src: menu_href)]
      end
    end

    # Subclasses can override inline `menu_items` or `menu_href` in order to control
    # what is displayed in the action menu.
    def menu_items = nil
    def menu_href = list_row_menu_project_path(project, status: params[:status])

    def action_menu(src: nil, items: nil)
      raise ArgumentError, "provide either src: or items:, not both" if src && items
      raise ArgumentError, "provide either src: or items:" unless src || items

      render(Primer::Alpha::ActionMenu.new(
               menu_id: Projects::RowActionsComponent.menu_id(project),
               test_selector: "project-list-row--action-menu",
               src:
             )) do |menu|
        menu.with_show_button(
          scheme: :invisible,
          size: :small,
          icon: :"kebab-horizontal",
          "aria-label": t(:label_open_menu),
          tooltip_direction: :w
        )
        items&.each do |action_options|
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

    def user_can_view_project_attributes?
      User.current.allowed_in_project?(:view_project_attributes, project)
    end

    def user_can_view_project_phases?
      User.current.allowed_in_project?(:view_project_phases, project)
    end

    def custom_field_column_subject
      project
    end

    def format_custom_field_value(cf, custom_value)
      if cf.field_format == "text" && custom_value.present?
        render OpenProject::Common::AttributeComponent.new(
          "dialog-#{project.id}-cf-#{cf.id}",
          cf.name,
          custom_value,
          format: false
        )
      elsif cf.calculated_value?
        render_calculated_value(cf, custom_value)
      else
        super
      end
    end

    def custom_field_column?(column)
      column.is_a?(::Queries::Projects::Selects::CustomField)
    end

    def custom_comment_column?(column)
      column.is_a?(::Queries::Projects::Selects::CustomComment)
    end

    def project_phase_column?(column)
      column.is_a?(::Queries::Projects::Selects::ProjectPhase)
    end

    def current_page
      table.model.current_page.to_s
    end
  end
end
