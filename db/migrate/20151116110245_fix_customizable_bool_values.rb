class FixCustomizableBoolValues < ActiveRecord::Migration[4.2]
  def up
    update_customizable_values(quoted_true, unquoted_true, quoted_false, unquoted_false)
  end

  def down
    update_customizable_values(unquoted_true, quoted_true, unquoted_false, quoted_false)
  end

  private

  def update_customizable_values(old_true, new_true, old_false, new_false)
    bool_custom_fields.each do |bool_custom_field|
      alter(CustomizableJournal, bool_custom_field, old_false, new_false)
      alter(CustomizableJournal, bool_custom_field, old_true, new_true)
    end
  end

  def bool_custom_fields
    @bool_custom_fields ||= CustomField.where(field_format: 'bool').all
  end

  def alter(scope, custom_field, old, new)
    scope
      .where(custom_field_id: custom_field.id,
             value: old)
      .update_all(value: new)
  end

  def quoted_false
    ActiveRecord::Base.connection.quoted_false
  end

  def quoted_true
    ActiveRecord::Base.connection.quoted_true
  end

  def unquoted_false
    ActiveRecord::Base.connection.unquoted_false
  end

  def unquoted_true
    ActiveRecord::Base.connection.unquoted_true
  end
end
