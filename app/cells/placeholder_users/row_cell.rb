module PlaceholderUsers
  class RowCell < ::RowCell
    include AvatarHelper
    include UsersHelper

    def placeholder_user
      model
    end

    def lastname
      link_to h(placeholder_user.name), edit_placeholder_user_path(placeholder_user)
    end

    def button_links
      [delete_link].compact
    end

    def delete_link
      return nil unless Users::DeleteService.deletion_allowed? placeholder_user, User.current

      link_to '',
              placeholder_user_path(placeholder_user),
              data: { confirm: 'Are you sure?' },
              class: 'icon icon-delete',
              method: :delete
    end
  end
end
