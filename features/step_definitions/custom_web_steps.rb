#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Then /^I should (not )?see "([^"]*)"\s*\#.*$/ do |negative, name|
  steps %Q{
    Then I should #{negative}see "#{name}"
  }
end

When /^I click(?:| on) "([^"]*)"$/ do |name|
  click_link_or_button(name)
end

When /^(?:|I )jump to [Pp]roject "([^\"]*)"$/ do |project|
  click_link('Projects')
  # supports both variants of finding: by class and by id
  # id is older and can be dropped later
  project_div = find(:css, '.project-search-results', :text => project) || find(:css, '#project-search-results', :text => project)

  page.execute_script("window.location = jQuery(\"##{project_div[:id]} div[title='#{project}']\").parent().data('select2Data').project.url;")
end

Then /^"([^"]*)" should be selected for "([^"]*)"$/ do |value, select_id|
  # that makes capybara wait for the ajax request
  find(:xpath, "//body")
  # if you wanna see ugly things, look at the following line
  (page.evaluate_script("$('#{select_id}').value") =~ /^#{value}$/).should be_present
end

Then /^"([^"]*)" should (not )?be selectable from "([^"]*)"$/ do |value, negative, select_id|
  #more page.evaluate ugliness
  find(:xpath, "//body")
  bool = negative ? false : true
  (page.evaluate_script("$('#{select_id}').select('option[value=#{value}]').first.disabled") =~ /^#{bool}$/).should be_present
end

# This does NOT trigger actual hovering by means of :hover.
# To use this, you have to adjust your stylesheet accordingly.
When /^I hover over "([^"]+)"$/ do |selector|
  page.execute_script "jQuery(#{selector.inspect}).addClass('hover');"
end

When /^I stop hovering over "([^"]*)"$/ do |selector|
  page.execute_script "jQuery(#{selector.inspect}).removeClass('hover');"
end
