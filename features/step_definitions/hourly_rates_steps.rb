#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

Given(/^there is an hourly rate with the following:$/) do |table|
  table_hash = table.rows_hash
  rate = FactoryGirl.create(:hourly_rate,
    valid_from: eval(table_hash[:valid_from]),
    user: User.find_by_login(table_hash[:user]),
    project: Project.find_by_name(table_hash[:project]),
    rate: table_hash[:rate].to_i)
end

When(/^I set the hourly rate of user "(.*?)" to "(.*?)"$/) do |arg1, arg2|
  user = User.find_by_login(arg1)
  within("tr#member-#{user.id}") do
    fill_in('rate', with: arg2)
    click_link_or_button('Save')
  end
end

Then(/^I should see (\d+) hourly rate[s]?$/) do |arg1|
  page.should have_css("tbody#rates_body tr", count: $1)
end
