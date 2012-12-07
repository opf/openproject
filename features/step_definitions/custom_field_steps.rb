Given /^the following (user|issue) custom fields are defined:$/ do |type, table|
  type = (type + "_custom_field").to_sym

  as_admin do
    table.hashes.each_with_index do |r, i|
      attr_hash = { :name => r['name'],
                    :field_format => r['type']}

      attr_hash[:possible_values] = r['possible_values'].split(",").collect(&:strip) if r['possible_values']
      attr_hash[:is_required] = (r[:required] == 'true') if r[:required]
      attr_hash[:editable] = (r[:editable] == 'true') if r[:editable]
      attr_hash[:visible] = (r[:visible] == 'true') if r[:visible]
      attr_hash[:default_value] = r[:default_value] ? r[:default_value] : nil
      attr_hash[:is_for_all] = r[:is_for_all] || true

      FactoryGirl.create type, attr_hash
    end
  end
end

Given /^the user "(.+?)" has the user custom field "(.+?)" set to "(.+?)"$/ do |login, field_name, value|
  user = User.find_by_login(login)
  custom_field = UserCustomField.find_by_name(field_name)

  user.custom_values.build(:custom_field => custom_field, :value => value)
  user.save!
end

Given /^the custom field "(.+)" is( not)? summable$/ do |field_name, negative|
  custom_field = IssueCustomField.find_by_name(field_name)

  Setting.issue_list_summable_columns = negative ?
                                          Setting.issue_list_summable_columns - ["cf_#{custom_field.id}"] :
                                          Setting.issue_list_summable_columns << "cf_#{custom_field.id}"
end
