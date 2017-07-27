module Members
  class UserFilterCell < ::UserFilterCell
    def initially_visible?
      false
    end

    ##
    # Adapts the user filter counts to count members as opposed to users.
    def extra_user_status_options
      {
        all: status_members_query('all').count,
        blocked: status_members_query('blocked').count,
        active: status_members_query('active').count,
        invited: status_members_query('invited').count,
        registered: status_members_query('registered').count,
        locked: status_members_query('locked').count
      }
    end

    def status_members_query(status)
      params = { project_id: project.id,
                 status: status }

      self.class.filter(params)
    end

    def self.base_query
      Queries::Members::MemberQuery
    end
  end
end
