def parse_password_rules(str)
  str.sub(', and ', ', ').split(', ')
end

Given /^passwords must contain ([0-9]+) of ([a-z, ]+) characters$/ do |minimum_rules, rules|
  rules = parse_password_rules(rules)
  Setting.password_active_rules = rules
  Setting.password_min_adhered_rules = minimum_rules.to_i
end

Given /^passwords have a minimum length of ([0-9]+) characters$/ do |minimum_length|
  Setting.password_min_length = minimum_length
end

Given /^I try to set my new password to "(.+)"$/ do |password|
  visit "/my/password"
  # use find and set with id to prevent ambigious match
  find('#password').set('adminADMIN!')

  fill_in('new_password', :with => password)
  fill_in('new_password_confirmation', :with => password)
  click_link_or_button 'Apply'
  @new_password = password
end

Given /^there should be an error describing the password complexity is too low$/ do
  should have_selector('#errorExplanation')
end

Given /^the password change should succeed$/ do
  find('.notice').should have_content('success')
end

Given /^I should be able to login using the new password$/ do
  visit('/logout')
  login(@user.login, @new_password)
end

Given /^I activate the ([a-z, ]+) password rules$/ do |rules|
  rules = parse_password_rules(rules)
  should have_selector(:xpath, "//input[@id='settings_password_active_rules_' and @value='#{rules.first}']")
  all(:xpath, "//input[@id='settings_password_active_rules_']").each do |checkbox|
    checkbox.set(false)
  end
  rules.each do |rule|
    find(:xpath, "//input[@id='settings_password_active_rules_' and @value='#{rule}']").set(true)
  end
end
