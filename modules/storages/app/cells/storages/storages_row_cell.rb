# Purpose: Defines the row model for the table of Storage objects
# Used by: Storage table in storages_table_cell.rb
# Reference: RubyCells???
module Storages
  class StoragesRowCell < ::RowCell
    include ::IconsHelper # Global helper for icons, defines op_icon and icon_wrapper?
    include ::AvatarHelper # Global helper for avatar (image of a user)
    include ::Redmine::I18n # Internationalization support (defines I18n.t(...) translation)

    def name
      link_to model.name, storage_path(model)
    end

    # Delegate delegates the execution of certain methods to :model.
    # ToDo: I'm not sure why this makes sense here.
    delegate :host, to: :model
    delegate :provider_type, to: :model

    def creator
      icon = avatar model.creator, size: :mini
      icon + model.creator.name
    end

    def button_links
      [edit_link, delete_link]
    end

    def delete_link
      link_to '',
              storage_path(model),
              class: 'icon icon-delete',
              data: { confirm: I18n.t('storages.delete_warning.storage') },
              title: I18n.t(:button_delete),
              method: :delete
    end

    def edit_link
      link_to '',
              edit_storage_path(model),
              class: 'icon icon-edit',
              accesskey: accesskey(:edit),
              title: I18n.t(:button_edit)
    end
  end
end
