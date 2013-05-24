Given(/^there is an hourly rate with the following:$/) do |table|
  table_hash = table.rows_hash
  rate = FactoryGirl.create(:hourly_rate,
    :valid_from => eval(table_hash[:valid_from]),
    :user => User.find_by_login(table_hash[:user]),
    :project => Project.find_by_name(table_hash[:project]),
    :rate => table_hash[:rate].to_i)
end

When(/^I set the hourly rate of user "(.*?)" to "(.*?)"$/) do |arg1, arg2|
  user = User.find_by_login(arg1)
  within("tr#member-#{user.id}") do
    fill_in('rate', with: arg2)
    click_button('Save')
  end
end

Then(/^I should see (\d+) hourly rate[s]?$/) do |arg1|
  page.should have_css("tbody#rates_body tr", count: $1)
end
