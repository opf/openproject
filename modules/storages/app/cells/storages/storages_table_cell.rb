# Purpose: Defines a table with the list of Storages::Storage
# objects in the global admin section of OpenProject
# Used by: the admin list of all storages in the system
# (storages/app/views/storages/admin/index.html.erb)
# Reference: https://trailblazer.to/2.0/gems/cells.html
# See also: storage_row_cell.rb with the row model of the table
module Storages
  class StoragesTableCell < ::TableCell
    include ::IconsHelper # Global helper for icons, defines op_icon(...)

    class << self
      def row_class
        ::Storages::StoragesRowCell
      end
    end

    # Defines the list of columns in the table using symbols.
    # These symbols are used below to define header (top of the table)
    # and contents of the cells
    columns :name, :provider_type, :host, :creator, :created_at

    # Default sort order (overwritten by user)
    def initial_sort
      %i[created_at asc]
    end

    # Should RubyCell show ^/v icons in the header to allow custom sorting?
    def sortable?
      false
    end

    # Used by: app/cells/views/table/show.erb and
    # Purpose: return the link to be used to create the storage
    def inline_create_link
      link_to(new_admin_settings_storage_path,
              class: 'wp-inline-create--add-link',
              title: I18n.t('storages.label_new_storage')) do
        op_icon('icon icon-add')
      end
    end

    # Show this pretty message if there are now Storages::Storage objects in the system
    def empty_row_message
      I18n.t 'storages.no_results'
    end

    # Definition of the table header using the keys from columns above.
    def headers
      [
        ['name', { caption: ::Storages::Storage.human_attribute_name(:name) }],
        ['provider_type', { caption: I18n.t('storages.provider_types.label') }],
        ['host', { caption: I18n.t('storages.label_host') }],
        ['creator', { caption: I18n.t('storages.label_creator') }],
        ['created_at', { caption: ::Storages::Storage.human_attribute_name(:created_at) }]
      ]
    end
  end
end
