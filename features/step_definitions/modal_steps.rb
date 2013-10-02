When(/^I open the modal window for the story "(.*?)"$/) do |subject|
  story = Story.find_by_subject(subject)

  within("#story_#{story.id}") do
    click_link(story.id)
  end
end

When(/^I switch the modal window into edit mode$/) do
  modal = find(".modal")

  within(modal) do
    click_link("Update")
  end

  safeguard_backlogs_modal_in_edit_mode
end

def safeguard_backlogs_modal_in_edit_mode
  find_field("work_package[description]")
end

