module FriendlyId
  module SequentiallySlugged
    def self.setup(model_class)
      model_class.friendly_id_config.use :slugged
    end

    def resolve_friendly_id_conflict(candidate_slugs)
      candidate = candidate_slugs.first
      return if candidate.nil?
      SequentialSlugCalculator.new(scope_for_slug_generator,
                                  candidate,
                                  friendly_id_config.slug_column,
                                  friendly_id_config.sequence_separator,
                                  slug_base_class).next_slug
    end

    class SequentialSlugCalculator
      attr_accessor :scope, :slug, :slug_column, :sequence_separator

      def initialize(scope, slug, slug_column, sequence_separator, base_class)
        @scope = scope
        @slug = slug
        table_name = scope.connection.quote_table_name(base_class.arel_table.name)
        @slug_column = "#{table_name}.#{scope.connection.quote_column_name(slug_column)}"
        @sequence_separator = sequence_separator
      end

      def next_slug
        slug + sequence_separator + next_sequence_number.to_s
      end

    private

      def next_sequence_number
        last_sequence_number ? last_sequence_number + 1 : 2
      end

      def last_sequence_number
        regexp = /#{slug}#{sequence_separator}(\d+)\z/
        # Reject slug_conflicts that doesn't come from the first_candidate
        # Map all sequence numbers and take the maximum
        slug_conflicts.reject{ |slug_conflict| !regexp.match(slug_conflict) }.map do |slug_conflict|
          regexp.match(slug_conflict)[1].to_i
        end.max
      end

      def slug_conflicts
        scope.
          where(conflict_query, slug, sequential_slug_matcher).
          order(Arel.sql(ordering_query)).pluck(Arel.sql(slug_column))
      end

      def conflict_query
        base = "#{slug_column} = ? OR #{slug_column} LIKE ?"
        # Awful hack for SQLite3, which does not pick up '\' as the escape character
        # without this.
        base << " ESCAPE '\\'" if scope.connection.adapter_name =~ /sqlite/i
        base
      end

      def sequential_slug_matcher
        # Underscores (matching a single character) and percent signs (matching
        # any number of characters) need to be escaped. While this looks like
        # an excessive number of backslashes, it is correct.
        "#{slug}#{sequence_separator}".gsub(/[_%]/, '\\\\\&') + '%'
      end

      # Return the unnumbered (shortest) slug first, followed by the numbered ones
      # in ascending order.
      def ordering_query
        length_command = "LENGTH"
        length_command = "LEN" if scope.connection.adapter_name =~ /sqlserver/i
        "#{length_command}(#{slug_column}) ASC, #{slug_column} ASC"
      end
    end

    private

    def slug_base_class
      if friendly_id_config.uses?(:history)
        Slug
      else
        self.class.base_class
      end
    end
  end
end
