# frozen_string_literal: true

module CostReports
  # Cost reports used to keep the filters a user was looking at in the session,
  # which made them leak between projects and browser tabs. They live on the URL
  # now, so a session left over from before is translated once and discarded.
  class SessionFilters
    KEY = :cost_query

    def initialize(session)
      @session = session
    end

    def any?
      stored.present? && (stored[:filters].present? || stored[:groups].present?)
    end

    def take!
      params = filters.to_params

      @session.delete(KEY)

      params
    end

    private

    def stored
      @session[KEY]
    end

    def filters
      LegacyFilters.new(operators: stored.dig(:filters, :operators),
                        values: stored.dig(:filters, :values),
                        rows: stored.dig(:groups, :rows),
                        columns: stored.dig(:groups, :columns))
    end
  end
end
