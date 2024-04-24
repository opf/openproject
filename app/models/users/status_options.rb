module Users
  module StatusOptions
    module_function

    ##
    # @param extra [Hash] A hash containing extra entries with a count for each.
    #                     For example: { random: 42 }
    # @return [Hash[Symbol, Integer]] A hash mapping each status symbol (such as :active, :blocked,
    #                               etc.) to its count (e.g. { active: 1, blocked: 5, random: 42).
    def user_statuses_with_count(extra: {})
      user_count_by_status(extra:)
        .compact
        .to_h
    end

    def user_count_by_status(extra: {})
      counts = User.user.group(:status).count.to_hash

      counts
        .merge(symbolic_user_counts)
        .merge(extra)
        .reject { |_, v| v.nil? } # remove nil counts to support dropping counts via extra
        .map do |k, v|
          known_status = Principal.statuses.detect { |_, i| i == k }
          if known_status
            [known_status.first.to_sym, v]
          else
            [k.to_sym, v]
          end
        end
        .to_h
    end

    def symbolic_user_counts
      {
        blocked: User.user.blocked.count, # User.user scope to skip DeletedUser
        all: User.user.count,
        active: User.user.active.not_blocked.count # User.user to skip Anonymous and System users
      }
    end
  end
end
