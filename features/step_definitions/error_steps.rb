#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

Then /^there should( not)? be an(?:y)? error message$/ do |no_message|
  if no_message
    should_not have_selector('#errorExplanation')
  else
    should have_selector('#errorExplanation')
  end
end

# This one aims at the rails flash based errors
Then /^I should see an error explanation stating "([^"]*)"$/ do |message|
  page.all(:css, '.errorExplanation li, .errorExplanation li *', text: message).should_not be_empty
end

# This one aims at the angular js notifications which can be errors
Then /^I should see an error notification stating "([^"]*)"$/ do |message|
  step "I should see \"#{message}\" within \".notification-box--errors li\""
end

Then /^there should( not)? be a flash (error|notice) message$/ do |no_message, kind_of_message|
  if no_message
    should_not have_selector(".flash.#{kind_of_message}")
  else
    should have_selector(".flash.#{kind_of_message}")
  end
end

Then /^the flash message should contain "([^"]*)"$/ do |message|
  page.find(:css, '.flash').text.should include(message)
end

Then /^I should( not)? see (\d+) error message(?:s)?$/ do |negative, count|
  equal = page.all('.errorExplanation').count == count.to_i
  negative ? (equal.should_not be_truthy) : (equal.should be_truthy)
end
