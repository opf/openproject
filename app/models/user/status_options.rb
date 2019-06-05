class User
  module StatusOptions
    module_function

    ##
    # @param extra [Hash] A hash containing extra entries with a count for each.
    #                     For example: { random: 42 }
    # @return [Hash[Symbol, Integer]] A hash mapping each status symbol (such as :active, :blocked,
    #                               etc.) to its count (e.g. { active: 1, blocked: 5, random: 42).
    def user_statuses_with_count(extra: {})
      user_count_by_status(extra: extra)
        .compact
        .to_h
    end

    def user_count_by_status(extra: {})
      counts = User.not_builtin.group(:status).count.to_hash

      counts
        .merge(symbolic_user_counts)
        .merge(extra)
        .reject { |_, v| v.nil? } # remove nil counts to support dropping counts via extra
        .map do |k, v|
          known_status = Principal::STATUSES.detect { |_, i| i == k }
          if known_status
            [known_status.first, v]
          else
            [k, v]
          end
        end
        .to_h
    end

    def symbolic_user_counts
      {
        blocked: User.blocked.count,
        all: User.not_builtin.count,
        active: User.active.not_blocked.count
      }
    end
  end
end
