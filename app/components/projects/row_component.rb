# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
    def project
      model.first
    end

    def level
      model.last
    end

    # Hierarchy cell is just a placeholder
    def hierarchy
      ''
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

      if cf.field_format == 'text' && custom_value.present?
        render OpenProject::Common::AttributeComponent.new("dialog-#{project.id}-cf-#{cf.id}", cf.name, custom_value.html_safe) # rubocop:disable Rails/OutputSafety
      elsif custom_value.is_a?(Array)
        safe_join(Array(custom_value).compact_blank, ', ')
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
      return '' unless project.required_disk_space.to_i > 0

      number_to_human_size(project.required_disk_space, precision: 2)
    end

    def name
      content = content_tag(:i, '', class: "projects-table--hierarchy-icon")

      if project.archived?
        content << ' '
        content << content_tag(:span, I18n.t('project.archive.archived'), class: 'archived-label')
      end

      content << ' '
      content << helpers.link_to_project(project, {}, {}, false)
      content
    end

    def project_status
      return nil unless user_can_view_project?

      content = ''.html_safe

      status_code = project.status_code

      if status_code
        classes = helpers.project_status_css_class(status_code)
        content << content_tag(:span, '', class: "project-status--bulb -inline #{classes}")
        content << content_tag(:span, helpers.project_status_name(status_code), class: "project-status--name #{classes}")
      end

      content
    end

    def status_explanation
      return nil unless user_can_view_project?

      if project.status_explanation.present? && project.status_explanation
        render OpenProject::Common::AttributeComponent.new("dialog-#{project.id}-status-explanation",
                                                           I18n.t('activerecord.attributes.project.status_explanation'),
                                                           project.status_explanation)
      end
    end

    def description
      return nil unless user_can_view_project?

      if project.description.present?
        render OpenProject::Common::AttributeComponent.new("dialog-#{project.id}-description",
                                                           I18n.t('activerecord.attributes.project.description'),
                                                           project.description)
      end
    end

    def public
      helpers.checked_image project.public?
    end

    def row_css_class
      classes = %w[basics context-menu--reveal]
      classes << project_css_classes
      classes << row_css_level_classes

      classes.join(" ")
    end

    def row_css_level_classes
      if level > 0
        "idnt idnt-#{level}"
      else
        ""
      end
    end

    def project_css_classes
      s = ' project '.html_safe

      s << ' root' if project.root?
      s << ' child' if project.child?
      s << (project.leaf? ? ' leaf' : ' parent')

      s
    end

    def column_css_class(column)
      "#{column.attribute} #{additional_css_class(column)}"
    end

    def additional_css_class(column)
      if column.attribute == :name
        "project--hierarchy #{project.archived? ? 'archived' : ''}"
      elsif [:status_explanation, :description].include?(column.attribute)
        "project-long-text-container"
      elsif custom_field_column?(column)
        cf = column.custom_field
        formattable = cf.field_format == 'text' ? ' project-long-text-container' : ''
        "format-#{cf.field_format}#{formattable}"
      end
    end

    def more_menu_items
      @more_menu_items ||= [more_menu_subproject_item,
                            more_menu_settings_item,
                            more_menu_activity_item,
                            more_menu_archive_item,
                            more_menu_unarchive_item,
                            more_menu_copy_item,
                            more_menu_delete_item].compact
    end

    def more_menu_subproject_item
      if User.current.allowed_in_project?(:add_subprojects, project)
        [t(:label_subproject_new),
         new_project_path(parent_id: project.id),
         { class: 'icon-context icon-add',
           title: t(:label_subproject_new) }]
      end
    end

    def more_menu_settings_item
      if User.current.allowed_in_project?({ controller: '/projects/settings/general', action: 'show', project_id: project.id },
                                          project)
        [t(:label_project_settings),
         project_settings_general_path(project),
         { class: 'icon-context icon-settings',
           title: t(:label_project_settings) }]
      end
    end

    def more_menu_activity_item
      if User.current.allowed_in_project?(:view_project_activity, project)
        [
          t(:label_project_activity),
          project_activity_index_path(project, event_types: ['project_attributes']),
          { class: 'icon-context icon-checkmark',
            title: t(:label_project_activity) }
        ]
      end
    end

    def more_menu_archive_item
      if User.current.allowed_in_project?(:archive_project, project) && project.active?
        [t(:button_archive),
         project_archive_path(project, status: params[:status]),
         { data: { confirm: t('project.archive.are_you_sure', name: project.name) },
           method: :post,
           class: 'icon-context icon-locked',
           title: t(:button_archive) }]
      end
    end

    def more_menu_unarchive_item
      if User.current.admin? && project.archived? && (project.parent.nil? || project.parent.active?)
        [t(:button_unarchive),
         project_archive_path(project, status: params[:status]),
         { method: :delete,
           class: 'icon-context icon-unlocked',
           title: t(:button_unarchive) }]
      end
    end

    def more_menu_copy_item
      if User.current.allowed_in_project?(:copy_projects, project) && !project.archived?
        [t(:button_copy),
         copy_project_path(project),
         { class: 'icon-context icon-copy',
           title: t(:button_copy) }]
      end
    end

    def more_menu_delete_item
      if User.current.admin
        [t(:button_delete),
         confirm_destroy_project_path(project),
         { class: 'icon-context icon-delete',
           title: t(:button_delete) }]
      end
    end

    def user_can_view_project?
      User.current.allowed_in_project?(:view_project, project)
    end

    def custom_field_column?(column)
      column.is_a?(Queries::Projects::Selects::CustomField)
    end
  end
end
