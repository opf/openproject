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

Given /^the "(.+)" drop-down should( not)? have the following options:$/ do |id, neg, table|
  meth = neg ? :should_not : :should
  table.raw.each do |option|
    page.send(meth, have_xpath("//select[@id = '#{id}']//option[@value = '#{option[0]}']"))
  end
end

Then /^the "(.+)" drop-down should have the following options (enabled|disabled):$/ do |id, state, table|
  state = state == 'disabled' ? '' : 'not'
  table.raw.each do |option|
    page.should have_xpath "//select[@id = '#{id}']//option[@value = '#{option[0]}' and #{state}(@disabled)]"
  end
end

Then /^the "(.+)" drop-down(?: inside "([^\"]*)")? should have "([^\"]*)" selected$/ do |field_name, selector, option_name|
  with_scope(selector) do
    find_field(field_name).find('option[selected]').text.should == option_name
  end
end

Then /^the "(.+)" drop-down should have the following sorted options:$/ do |field_name, table|
  find_field(field_name).all('option').map(&:text).should == table.raw.flatten
end
