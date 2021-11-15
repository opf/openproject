class CleanCustomValues < ActiveRecord::Migration[5.2]
  def up
    invalid_cv = CustomValue
      .joins(:custom_field)
      .where("#{CustomField.table_name}.field_format = 'list'")
      .where.not(value: '')
      .where("value !~ '^[0-9]+$'")

    if invalid_cv.count > 0
      warn_string = "Replacing invalid list custom values:\n"
      invalid_cv.pluck(:customized_type, :customized_id, :value).each do |customized_type, customized_id, value|
        warn_string << "- #{customized_type} ##{customized_id}: Value was #{value.inspect}\n"
      end

      warn warn_string
      invalid_cv.update_all(value: '')
    end
  end

  def down
    # This migration does not restore data
  end
end
