module Users
  class RowCell < ::RowCell
    include AvatarHelper
    include UsersHelper

    def user
      model
    end

    def row_css_class
      status = %w(anon active registered locked)[user.status]
      blocked = "blocked" if user.failed_too_many_recent_login_attempts?

      ["user", status, blocked].compact.join(" ")
    end

    def login
      icon = avatar user, class: 'avatar-mini'
      link = link_to h(user.login), edit_user_path(user)

      icon + link
    end

    def mail
      mail_to user.mail
    end

    def admin
      checked_image user.admin?
    end

    def last_login_on
      format_time user.last_login_on unless user.last_login_on.nil?
    end

    def status
      full_user_status user
    end

    def button_links
      [status_link].compact
    end

    def status_link
      change_user_status_links user unless user.id == table.current_user.id
    end

    def column_css_class(column)
      if column == :mail
        "email"
      elsif column == :login
        "username"
      else
        super
      end
    end
  end
end
