When(/^I open the modal window for the story "(.*?)"$/) do |subject|
  story = Story.find_by_subject(subject)

  within("#story_#{story.id}") do
    click_link(story.id)
  end
end

When(/^I switch the modal window into edit mode$/) do
  browser = page.driver.browser
  browser.switch_to.frame("modalIframe")
  within("#content > .action_menu_main") do
    click_link("Update")
  end
  within("fieldset.tabular") do
    click_link("More")
  end
  safeguard_backlogs_modal_in_edit_mode
end

And(/^I switch out of the modal$/) do
  browser = page.driver.browser
  browser.switch_to.default_content
end

def safeguard_backlogs_modal_in_edit_mode
  find_field("work_package[description]")
end

