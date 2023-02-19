# Purpose: Defines how to format the cells within a table of ProjectStorages
# associated with a project
# Used by: projects_storages_table_cell.rb - the methods defined here
# correspond to the columns value in the table model.
# See for more comments: storage_row_cell.rb
module Storages
  class ProjectsStoragesRowCell < ::RowCell
    include ::IconsHelper
    include ::AvatarHelper
    include ::Redmine::I18n

    def name
      model.storage.name
    end

    def provider_type
      model.storage.provider_type
    end

    def creator
      icon = avatar model.creator, size: :mini
      icon + model.creator.name
    end

    def button_links
      [delete_link]
    end

    def delete_link
      link_to '',
              project_settings_projects_storage_path(project_id: model.project, id: model),
              class: 'icon icon-delete',
              data: { confirm: I18n.t('storages.delete_warning.project_storage') },
              title: I18n.t(:button_delete),
              method: :delete
    end
  end
end
