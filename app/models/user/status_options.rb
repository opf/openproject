class User
  module StatusOptions
    module_function

    ##
    # @param extra [Hash] A hash containing extra entries with a count for each.
    #                     For example: { random: 42 }
    # @return [Hash[Symbol, Array]] A hash mapping each status symbol (such as :active, :blocked,
    #                               etc.) to its count and value (e.g. :active => 1,
    #                               :blocked => :blocked) in a tuple.
    def user_statuses_with_count(extra: {})
      counts = user_count_by_status extra: extra
      symbols = status_symbols extra: extra

      symbols
        .map { |name, id| status_count_value_tuple name, id, counts }
        .compact
        .to_h
    end

    def status_count_value_tuple(name, id, counts)
      value = (counts.include?(id) && id) || User::STATUSES[id] # :active => 1
      count = counts[value]

      [name.to_sym, [count.to_i, value]] if count
    end

    # use non-numerical values as index to prevent clash with normal user
    # statuses
    def status_symbols(extra: {})
      { all: :all, blocked: :blocked }
        .merge(User::STATUSES.except(:builtin))
        .merge(extra.map { |key, _| [key, key] }.to_h)
    end

    def user_count_by_status(extra: {})
      counts = User.group(:status).count.to_hash

      counts
        .merge(symbolic_user_counts)
        .merge(extra)
        .reject { |_, v| v.nil? } # remove nil counts to support dropping counts via extra
        .map { |k, v| [User::STATUSES[k] || k, v] } # map to status id if :active, :invited etc.
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
