module PlaceholderUsers
  class PlaceholderUserFilterCell < ::PlaceholderUserFilterCell
    def filter_role(query, role_id)
      super.uniq
    end

    def clear_url
      placeholder_users_path
    end
  end
end
