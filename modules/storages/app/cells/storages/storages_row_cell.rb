module Storages
  class StoragesRowCell < ::RowCell
    include ::IconsHelper
    include ::AvatarHelper
    include ::Redmine::I18n

    def name
      link_to model.name, storage_path(model)
    end

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
