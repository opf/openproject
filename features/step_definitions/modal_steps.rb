When(/^I open the modal window for the story "(.*?)"$/) do |subject|
  story = Story.find_by_subject(subject)

  within("#story_#{story.id}") do
    click_link(story.id)
  end
end

When(/^I switch the modal window into edit mode$/) do
  click_link("Update")
end

