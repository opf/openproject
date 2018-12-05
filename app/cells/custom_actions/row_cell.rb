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
        delete_link
      ]
    end

    def edit_link
      link_to(
        op_icon('icon icon-edit'),
        edit_custom_action_path(action),
        title: t(:button_edit)
      )
    end

    def delete_link
      link_to(
        op_icon('icon icon-delete'),
        custom_action_path(action),
        method: :delete,
        data: { confirm: I18n.t(:text_are_you_sure) },
        title: t(:button_delete)
      )
    end
  end
end
