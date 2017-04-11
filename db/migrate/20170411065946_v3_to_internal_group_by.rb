class V3ToInternalGroupBy < ActiveRecord::Migration[5.0]
  class Query < ActiveRecord::Base; end

  # Copied from ::API::Utilities::PropertyNameConverter
  # and stripped down to the migration's requirements.
  class PropertyNameConverter
    class << self
      WELL_KNOWN_AR_TO_API_CONVERSIONS = {
        assigned_to: 'assignee',
        fixed_version: 'version',
        done_ratio: 'percentageDone',
        estimated_hours: 'estimatedTime',
        created_on: 'createdAt',
        updated_on: 'updatedAt'
      }.freeze

      # Converts the attribute name as refered to by the APIv3 to the source name of the attribute
      def to_ar_name(attribute)
        attribute = underscore_attribute attribute.to_s.underscore
        attribute = collapse_custom_field_name(attribute)

        special_conversion = special_api_to_ar_conversions[attribute]

        if special_conversion
          special_conversion
        else
          attribute
        end
      end

      private

      def special_api_to_ar_conversions
        @api_to_ar_conversions ||= WELL_KNOWN_AR_TO_API_CONVERSIONS.inject({}) do |result, (k, v)|
          result[v.underscore] = k.to_s
          result
        end
      end

      # collapses long custom field column names to be represented in their short form
      # (e.g. custom_field_1 -> cf_1)
      def collapse_custom_field_name(attribute)
        match = attribute.match /\Acustom_field_(?<id>\d+)\z/

        if match
          "cf_#{match[:id]}"
        else
          attribute
        end
      end

      def underscore_attribute(attribute)
        # vanilla underscore will not puts underscores between letters and digits
        # we add them with the power of regex (esp. used for custom fields)
        attribute.underscore.gsub(/([a-z])(\d)/, '\1_\2')
      end
    end
  end

  def up
    group_bys = V3ToInternalGroupBy::Query
                .where
                .not(group_by: [nil, ''])
                .pluck(:group_by)
                .uniq

    group_bys.each do |group_by|
      converted_group_by = V3ToInternalGroupBy::PropertyNameConverter
                           .to_ar_name(group_by)
      if group_by != converted_group_by
        V3ToInternalGroupBy::Query
          .where(group_by: group_by)
          .update_all(group_by: converted_group_by)
      end
    end
  end

  def down
    # No down migration as the migration is fixing corrupt data.
  end
end
