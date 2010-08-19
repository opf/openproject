Given /^the following stories:$/ do |stories|
  Story.create!(stories.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) story$/ do |pos|
  visit stories_path
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following stories:$/ do |expected_stories_table|
  expected_stories_table.diff!(tableish('table tr', 'td,th'))
end
