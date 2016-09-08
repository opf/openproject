class WorkPackage
  class AbstractCosts
    attr_reader :user
    attr_reader :project

    def initialize(user: User.current, project: nil)
      @user = user
      @project = project
    end

    ##
    # Adds to the given WorkPackage query's result an extra costs column.
    #
    # @param work_package_scope [WorkPackage::ActiveRecord_Relation]
    # @return [WorkPackage::ActiveRecord_Relation] The query with the joined costs.
    def add_to_work_packages(work_package_scope)
      add_costs_to work_package_scope
    end

    ##
    # For the given work packages calculates the sum of all costs.
    #
    # @param [WorkPackage::ActiveRecord_Relation | Array[WorkPackage]] List of work packages.
    # @return [Float] The sum of the work packages' costs.
    def costs_of(work_packages:)
      # N.B. Because of an AR quirks the code below uses statements like
      #   where(work_package_id: ids)
      # You would expect to be able to simply write those as
      #   where(work_package: work_packages)
      # However, AR (Rails 4.2) will not expand :includes + :references inside a subquery,
      # which will render the query invalid. Therefore we manually extract the IDs in a separate (pluck) query.
      wp_ids = work_package_ids work_packages

      filter_authorized(costs_model.where(work_package_id: wp_ids).joins(work_package: :project))
        .sum(costs_value)
        .to_f
    end

    ##
    # The model on which the costs calculations are based.
    # Can be any model which has the fields `overridden_costs` and `costs`
    # and is related to work packages (i.e. has a `work_package_id` too).
    #
    # @return [Class] Class of the model the costs are based on, e.g. CostEntry or TimeEntry.
    def costs_model
      raise NotImplementedError, "subclass responsiblity"
    end

    private

    def work_package_ids(work_packages)
      if work_packages.respond_to?(:pluck)
        work_packages.pluck(:id)
      else
        Array(work_packages).map { |wp| wp.id }
      end
    end

    def costs_table_name
      costs_model.table_name
    end

    def table_alias
      "#{costs_table_name}_sum_per_wp"
    end

    def add_costs_to(scope)
      query = costs.to_sql

      scope
        .joins(
          "LEFT JOIN (#{query}) as #{table_alias} ON #{table_alias}.wp_id = #{wp_table.name}.id")
        .select("#{table_alias}.#{costs_table_name}_sum")
    end

    def costs
      filter_authorized all_costs
    end

    def all_costs
      WorkPackage
        .joins(sum_arel.join_sources)
        .select("work_packages.id as wp_id, #{costs_sum} as #{costs_table_name}_sum")
        .group(wp_table[:id])
    end

    def costs_sum
      "SUM(#{costs_value})"
    end

    def costs_value
      "COALESCE(#{costs_table_name}.overridden_costs, #{costs_table_name}.costs)"
    end

    ##
    # Narrows down the query to only include costs visible to the user.
    #
    # @param [ActiveRecord::QueryMethods] Some query.
    # @return [ActiveRecord::QueryMethods] The filtered query.
    def filter_authorized(scope)
      scope # allow all
    end

    def sum_arel
      wp_table
        .from(wp_table)
        .join(ce_table, Arel::Nodes::OuterJoin).on(ce_table[:work_package_id].eq(wp_table[:id]))
        .join(projects_table).on(projects_table[:id].eq(wp_table[:project_id]))
        .group(wp_table[:id])
    end

    def wp_table
      WorkPackage.arel_table
    end

    def ce_table
      costs_model.arel_table
    end

    def projects_table
      Project.arel_table
    end
  end
end
