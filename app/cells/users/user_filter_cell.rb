module Users
  class UserFilterCell < ::UserFilterCell
    def filter_role(query, role_id)
      super.uniq
    end

    def clear_url
      users_path
    end
  end
end
