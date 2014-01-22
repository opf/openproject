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

When(/^I create a budget with the following:$/) do |table|

  rows = table.rows_hash

  steps %Q{And I toggle the "Budgets" submenu
           And I follow "New Budget" within "#main-menu"
           And I fill in "Subject" with "#{rows['subject']}"}

  click_button(I18n.t(:button_create), :exact => true)
end

When(/^I create the budget$/) do
	click_button(I18n.t(:button_create), :exact => true)
end

When(/^I setup a budget with the following:$/) do |table|

  rows = table.rows_hash

  steps %Q{And I toggle the "Budgets" submenu
           And I follow "New Budget" within "#main-menu"
           And I fill in "Subject" with "#{rows['subject']}"}
end

When(/^I (?:create|update) (?:a|the) (labor|material) item in row (\d+) with the following:$/) do | type, row_nr, table|
	rows = table.rows_hash
	unit = (type == 'labor') ? 'hours' : 'units'

	page.find("##{type}_budget_items_body tr:nth-child(#{row_nr}) .units input").set(rows[unit])
	page.find("##{type}_budget_items_body tr:nth-child(#{row_nr}) .comment input").set(rows['comment'])

    if type == 'labor'
	  page.find(:xpath, "//tbody[@id='#{type}_budget_items_body']/tr[#{row_nr}]//option[contains(., '#{rows['user']}')]").select_option
	end
end

When(/^I add a new (labor|material) item$/) do | type|
	steps %Q{ When I click on "Add Planned Costs" within "fieldset##{type}_budget_items_fieldset" }
end

Then (/^the planned (labor|material) costs in row (\d+) should be (.+)$/) do | type, row_nr, amount|
	steps %Q{ Then I should see #{amount} within "##{type}_budget_items_body tr:nth-child(#{row_nr}) td.currency" }
end

Then (/^the stored planned (labor|material) costs in row (\d+) should be (.+)$/) do | type, row_nr, amount|
	steps %Q{ Then I should see #{amount} within ".splitcontentleft .#{type}_budget_items.list tr:nth-child(#{row_nr}) td.currency" }
end

Then (/^the stored total planned (labor|material) costs should be (.+)$/) do | type, amount|
	steps %Q{ Then I should see #{amount} within ".splitcontentleft .#{type}_budget_items.list tr:last-child td.currency" }
end

Then (/^I should be able to update the budget "(.+)"$/) do | budget |
	steps %Q{ Then I should be on the show page for the budget "#{budget}"
			  And I should see "Update" within "div#update" }
end
