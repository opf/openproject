When(/^I create a budget with the following:$/) do |table|

  rows = table.rows_hash

  steps %Q{And I toggle the "Budgets" submenu
           And I follow "New Budget" within "#main-menu"
           And I fill in "Subject" with "#{rows['subject']}"}

  click_button(I18n.t(:button_create), :exact => true)
end
