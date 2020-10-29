# frozen_string_literal: true

module Doorkeeper
  module Orm
    module ActiveRecord
      # Helper class to clear stale and non-active tokens and grants.
      # Used by Doorkeeper Rake tasks.
      #
      class StaleRecordsCleaner
        def initialize(base_scope)
          @base_scope = base_scope
        end

        # Clears revoked records
        def clean_revoked
          table = @base_scope.arel_table

          @base_scope.where.not(revoked_at: nil)
            .where(table[:revoked_at].lt(Time.current))
            .in_batches(&:delete_all)
        end

        # Clears expired records
        def clean_expired(ttl)
          table = @base_scope.arel_table

          @base_scope.where(table[:created_at].lt(Time.current - ttl))
            .in_batches(&:delete_all)
        end
      end
    end
  end
end
