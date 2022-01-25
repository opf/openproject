module Storages
  class StoragesRowCell < ::RowCell
    include ::IconsHelper
    include ::AvatarHelper
    include ::Redmine::I18n

    def name
      model.name
    end

    def provider_type
      model.provider_type
    end

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
              data: { confirm: I18n.t(:text_are_you_sure) },
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
