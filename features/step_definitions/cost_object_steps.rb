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

  # Here's why we need the following ugly hack of waiting two seconds.
  #
  # This step (When I create a labor item...) enters hours and selects a user.
  # When doing this, for each change of these form field, an AJAX request will be sent to
  # attempt to calculate the total costs. The hours field only checks once per second
  # for a change (possibly to not send a request with each typed word), the user field
  # immediately sends the request.
  # This can lead to a scenario where our automation updates both hours and users field
  # before the first request is sent (as it may wait a second). Thus, the first request
  # already returns correct total costs and a following step finds the expected cost,
  # (e.g. "296.00 EUR") and cucumber continues to submit the form. Once the form is submitted,
  # the form field might detect a change and send an AJAX request (unnecessarily, but the
  # field obviously doesn't know that). The Rails application first processes the form,
  # adds a flash message to the session and returns a redirect to the show action.
  # When Rails processes the second request (the AJAX request, not the show action),
  # it clears the flash message without our base layout being able to show it.
  # The following request to the show action then can't show the flash message
  # and the expectation below for "Successful update" fails.
  #
  # Waiting 2 seconds gives the form field update JavaScript enough time to detect
  # a change and send the AJAX request before the form is submitted.
  #
  # This fixes the following sometimes failing scenarios:
  # * Budgets with cost items can be created adding new cost items
  # * Budgets can be updated updating existing cost items
  # * Budgets can be updated with new cost items
  sleep 2
end

When(/^I add a new (labor|material) item$/) do | type|
  steps %Q{ When I click on "Add Planned Costs" within "fieldset##{type}_budget_items_fieldset" }
end

Then (/^the planned (labor|material) costs in row (\d+) should be (.+)$/) do | type, row_nr, amount|
  steps %Q{ Then I should see #{amount} within "##{type}_budget_items_body tr:nth-child(#{row_nr}) td.currency" }
end

Then (/^the stored planned (labor|material) costs in row (\d+) should be (.+)$/) do | type, row_nr, amount|
  steps %Q{ Then I should see #{amount} within ".grid-content .#{type}_budget_items.list tr:nth-child(#{row_nr}) td.currency" }
end

Then (/^the stored total planned (labor|material) costs should be (.+)$/) do | type, amount|
  steps %Q{ Then I should see #{amount} within ".grid-content .#{type}_budget_items.list tr:last-child td.currency" }
end

Then (/^I should be able to update the budget "(.+)"$/) do | budget |
  steps %Q{ Then I should be on the show page for the budget "#{budget}"
        And I should see "Update" within "div#update" }
end
