module Users
  class UserFilterCell < ::UserFilterCell
    def filter_role(query, role_id)
      super.uniq
    end
  end
end
