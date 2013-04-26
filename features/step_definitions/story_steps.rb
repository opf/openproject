Then(/^the available status of the story called "(.+?)" should be the following:$/) do |story_name, table|
  # the order of the available status is important
  story = Story.find_by_subject(story_name)

  expected = table.raw.flatten.join(" ")

  within("#story_#{story.id} .editors") do
    should have_field("status_id", :text => expected)
  end
end


Then(/^the displayed attributes of the story called "(.+?)" should be the following:$/) do |story_name, table|
  story = Story.find_by_subject(story_name)

  within("#story_#{story.id}") do
    table.rows_hash.each do |key, value|
      case key
      when "Status"
        within(".status_id") do
          should have_selector("div.t", :text => value)
        end
      else
        raise "Not an implemented attribute"
      end
    end
  end
end

Then(/^the editable attributes of the story called "(.+?)" should be the following:$/) do |story_name, table|
  story = Story.find_by_subject(story_name)

  within("#story_#{story.id} .editors") do
    table.rows_hash.each do |key, value|
      case key
      when "Status"
        should have_select("status_id", :text => value)
      else
        raise "Not an implemented attribute"
      end
    end
  end
end
