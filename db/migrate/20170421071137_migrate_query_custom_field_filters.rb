##
# Updates filter values for list custom fields so that they refer
# to the newly introduced CustomOption IDs. If no custom option can
# be found for a filter value the value remains so it can be tried
# to restore or map it by hand.
class MigrateQueryCustomFieldFilters < ActiveRecord::Migration[5.0]
  def up
    # Don't validate in case there are queries which are already invalid.
    # It's not our responsibility here to fix corrupt data.
    update_query_filters! validate: false do |filter|
      update_filter_values! filter
    end
  end

  def down
    # don't validate as the custom value validation will fail
    # with the current code expecting custom option IDs
    update_query_filters! validate: false do |filter|
      rollback_filter_values! filter
    end
  end

  def update_query_filters!(validate: true)
    Query.all.each do |query|
      update = false

      query.filters.each do |filter|
        if list_custom_field? filter
          update = true

          yield filter
        end
      end

      query.save!(validate: validate) if update
    end
  end

  def update_filter_values!(filter)
    filter.values = filter.values.map do |value|
      id = find_custom_option_id(value, filter)

      if id
        id
      else
        warning =
          "[warning] No custom option found for CustomFieldFilter value: " +
          "#{value} (CF #{filter.custom_field.id})"

        puts warning

        value
      end
    end
  end

  def rollback_filter_values!(filter)
    filter.values = filter.values.map do |value|
      custom_option = CustomOption.where(custom_field: filter.custom_field, id: value).first

      if custom_option
        custom_option.value
      else
        value # this value likely could not be migrated to begin with so don't roll it back
      end
    end
  end

  def find_custom_option_id(value, filter)
    CustomOption
      .where(custom_field: filter.custom_field, value: value)
      .limit(1)
      .map(&:id)
      .first
  end

  def list_custom_field?(filter)
    filter.is_a?(Queries::WorkPackages::Filter::CustomFieldFilter) &&
      filter.custom_field && filter.custom_field.field_format == "list"
  end
end
