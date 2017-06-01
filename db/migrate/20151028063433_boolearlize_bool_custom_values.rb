class BoolearlizeBoolCustomValues < ActiveRecord::Migration[4.2]
  def up
    update_custom_values(fake_true, db_true, fake_false, db_false)
    update_queries(fake_true, db_true_unquoted, fake_false, db_false_unquoted)
  end

  def down
    update_custom_values(db_true, fake_true, db_false, fake_false)
    update_queries(db_true_unquoted, fake_true, db_false_unquoted, fake_false)
  end

  private

  def update_custom_values(old_true, new_true, old_false, new_false)
    bool_custom_fields.each do |bool_custom_field|
      alter(CustomValue, bool_custom_field, old_false, new_false)
      alter(CustomValue, bool_custom_field, old_true, new_true)
      alter(CustomizableJournal, bool_custom_field, old_false, new_false)
      alter(CustomizableJournal, bool_custom_field, old_true, new_true)
    end
  end

  def update_queries(old_true, new_true, old_false, new_false)
    queries = Query.all

    queries.each do |query|
      query.filters.each do |filter|
        update_filter(filter, old_true, new_true, old_false, new_false)
      end
      query.save(validate: false) # if we validate new code is run depending on role_permissions which do not exist yet
    end
  end

  def update_filter(filter, old_true, new_true, old_false, new_false)
    custom_field_match = filter.field.to_s.match(/\Acf_(\d+)\z/)

    return unless custom_field_match

    custom_field_id = custom_field_match[1].to_i

    bool_custom_field = bool_custom_fields.find { |cf| cf.id == custom_field_id }

    return unless bool_custom_field

    filter
      .values
      .map! { |v| v == old_false ? new_false : v }
      .map! { |v| v == old_true ? new_true : v }
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

  def db_false
    ActiveRecord::Base.connection.quoted_false
  end

  def db_true
    ActiveRecord::Base.connection.quoted_true
  end

  def db_false_unquoted
    ActiveRecord::Base.connection.unquoted_false
  end

  def db_true_unquoted
    ActiveRecord::Base.connection.unquoted_true
  end

  def fake_false
    '0'
  end

  def fake_true
    '1'
  end
end
