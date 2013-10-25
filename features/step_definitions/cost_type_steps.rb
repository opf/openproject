Given /^there is 1 cost type with the following:$/ do |table|
  ct = FactoryGirl.build(:cost_type)
  send_table_to_object(ct, table, {
    :cost_rate => Proc.new do |o,v|
      FactoryGirl.create(:cost_rate, :rate => v,
                                     :cost_type => o)
    end,
    :name => Proc.new do |o,v|
      o.name = v
      o.unit = v
      o.unit_plural = "#{v}s"
      o.save!
    end})
end

When(/^I delete the cost type "(.*?)"$/) do |name|
  step %{I go to the index page of cost types}

  ct = CostType.find_by_name name

  within ("#delete_cost_type_#{ct.id}") do
    find('input[type=image]').click
  end

  if page.driver.is_a? Capybara::Selenium::Driver
    # confirm "really delete?"
    page.driver.browser.switch_to.alert.accept
  end
end

Then(/^the cost type "(.*?)" should not be listed on the index page$/) do |name|

  if has_css?(".cost_types")
    within ".cost_types" do
      should_not have_link(name)
    end
  end
end

Then(/^the cost type "(.*?)" should be listed as deleted on the index page$/) do |name|
  check(I18n.t(:caption_show_locked))

  click_link(I18n.t(:button_apply))

  within ".deleted_cost_types" do
    should have_text(name)
  end
end



