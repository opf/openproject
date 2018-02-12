module CustomActions
  class RowCell < ::RowCell
    include ::IconsHelper

    def action
      model
    end

    def users
      synchronized_group.users.count
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
