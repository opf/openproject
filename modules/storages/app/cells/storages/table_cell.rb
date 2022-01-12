module Storages
  class TableCell < ::TableCell
    include ::IconsHelper
    columns :name, :provider_type, :creator, :created_at

    def initial_sort
      %i[created_at asc]
    end

    def sortable?
      false
    end

    def inline_create_link
      link_to(new_storage_path,
              class: 'wp-inline-create--add-link',
              title: I18n.t('storages.label_new_storage')) do
        op_icon('icon icon-add')
      end
    end

    def empty_row_message
      I18n.t 'storages.no_results'
    end

    def headers
      [
        ['name', { caption: Storages::Storage.human_attribute_name(:name) }],
        ['provider_type', { caption: I18n.t('storages.provider_types.label') }],
        ['creator', { caption: I18n.t('storages.label_creator') }],
        ['created_at', { caption: Storages::Storage.human_attribute_name(:created_at) }]
      ]
    end
  end
end
