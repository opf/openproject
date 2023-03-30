# Purpose: Defines how to format the cells within a table of ProjectStorages
# associated with a project
# Used by: projects_storages_table_cell.rb - the methods defined here
# correspond to the columns value in the table model.
# See for more comments: storage_row_cell.rb
module Storages::ProjectsStorages
  class RowComponent < ::RowComponent
    include ::IconsHelper
    include ::AvatarHelper
    include ::Redmine::I18n
    def project_storage
      row
    end

    delegate :created_at, to: :project_storage

    def name
      project_storage.storage.name
    end

    def provider_type
      project_storage.storage.provider_type
    end

    def creator
      icon = avatar project_storage.creator, size: :mini
      icon + project_storage.creator.name
    end

    def button_links
      [delete_link]
    end

    def delete_link
      link_to '',
              project_settings_projects_storage_path(project_id: project_storage.project, id: project_storage),
              class: 'icon icon-delete',
              data: { confirm: I18n.t('storages.delete_warning.project_storage') },
              title: I18n.t(:button_delete),
              method: :delete
    end
  end
end
