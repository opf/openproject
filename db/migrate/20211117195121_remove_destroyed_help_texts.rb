class RemoveDestroyedHelpTexts < ActiveRecord::Migration[6.1]
  def up
    custom_field_ids = CustomField
      .pluck(:id)
      .map { |id| "custom_field_#{id}"}

    AttributeHelpText
      .where("attribute_name LIKE 'custom_field_%'")
      .where.not(attribute_name: custom_field_ids)
      .destroy_all
  end

  def down
    # Nothing to do
  end
end
