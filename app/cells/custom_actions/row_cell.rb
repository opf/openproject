module CustomActions
  class RowCell < ::RowCell
    include ::IconsHelper
    include ReorderLinksHelper

    def action
      model
    end

    def name
      link_to h(action.name), edit_custom_action_path(action)
    end

    def sort
      reorder_links('custom_action', { action: 'update', id: action }, method: :put)
    end

    def button_links
      [
        edit_link,
        delete_link(custom_action_path(action))
      ]
    end

    def edit_link
      link_to t(:button_edit),
              edit_custom_action_path(action),
              class: 'icon icon-edit'
    end
  end
end
