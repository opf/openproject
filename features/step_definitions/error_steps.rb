#encoding: utf-8

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

Then /^there should( not)? be an(?:y)? error message$/ do |no_message|
  if no_message
    should_not have_selector('#errorExplanation')
  else
    should have_selector('#errorExplanation')
  end
end

Then /^I should see an error explanation stating "([^"]*)"$/ do |message|
  page.all(:css, ".errorExplanation li, .errorExplanation li *", :text => message).should_not be_empty
end

Then /^there should( not)? be a flash (error|notice) message$/ do |no_message, kind_of_message|
  if no_message
    should_not have_selector(".flash.#{kind_of_message}")
  else
    should have_selector(".flash.#{kind_of_message}")
  end
end

Then /^the flash message should contain "([^"]*)"$/ do |message|
  page.find(:css, '.flash > a').text.should include(message)
end

Then /^I should( not)? see (\d+) error message(?:s)?$/ do |negative, count|
  equal = page.all('.errorExplanation').count == count.to_i
  negative ? (equal.should_not be_true) : (equal.should be_true)
end
