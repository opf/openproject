Given(/^there is an hourly rate with the following:$/) do |table|
  table_hash = table.rows_hash
  rate = HourlyRate.new
  rate.valid_from = eval(table_hash[:valid_from])
  rate.user = User.find_by_login(table_hash[:user])
  rate.project = Project.find_by_name(table_hash[:project])
  rate.rate = table_hash[:rate].to_i
  rate.save!
end

When(/^I set the hourly rate of member "(.*?)" to "(.*?)"$/) do |arg1, arg2|
  within("tr#member-#{arg1}") do
    fill_in('rate', with: arg2)
    click_button('Save')
  end
end

Then(/^I should see (\d+) hourly rate[s]?$/) do |arg1|
  page.should have_css("tbody#rates_body tr", count: $1)
end
