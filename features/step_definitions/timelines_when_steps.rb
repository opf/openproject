When /^I move "([^"]*)" to the top$/ do |name|
  cell = find(:css, "table.list td", :text => Regexp.new("^#{name}$"))
  row = cell.find(:xpath, './ancestor::tr')
  link = row.find_link('Move to top')
  link.click
end

When /^I move "([^"]*)" to the bottom$/ do |name|
  cell = find(:css, "table.list td", :text => Regexp.new("^#{name}$"))
  row = cell.find(:xpath, './ancestor::tr')
  link = row.find_link('Move to bottom')
  link.click
end

When /^I move "([^"]*)" up by one$/ do |name|
  cell = find(:css, "table.list td", :text => Regexp.new("^#{name}$"))
  row = cell.find(:xpath, './ancestor::tr')
  link = row.find_link('Move up')
  link.click
end

When /^I move "([^"]*)" down by one$/ do |name|
  cell = find(:css, "table.list td", :text => Regexp.new("^#{name}$"))
  row = cell.find(:xpath, './ancestor::tr')
  link = row.find_link('Move down')
  link.click
end

When /^I fill in the planning element ID of "([^"]*)" with (\d+) star for "([^"]*)"$/ do |planning_element_name, number_hash_keys, container|
  planning_element = Timelines::PlanningElement.find_by_name(planning_element_name)
  text = "#{('*' * number_hash_keys.to_i)}#{planning_element.id}"

  step %Q{I fill in "#{text}" for "#{container}"}
end

When /^I follow the planning element link with (\d+) star for "([^"]*)"$/ do |star_count, planning_element_name|
  planning_element = Timelines::PlanningElement.find_by_name(planning_element_name)

  text = ""
  if star_count.to_i > 1
    text = "*#{planning_element.id} #{planning_element.planning_element_status.nil? ? "" : planning_element.planning_element_status.name + ":"} #{planning_element.name}"
  elsif star_count.to_i == 1
    text = "*#{planning_element.id}"
  end

  step %Q{I follow "#{text}"}
end

When /^I fill in a wiki macro for timeline "([^"]*)" for "([^"]*)"$/ do |timeline_name, container|
  timeline = Timelines::Timeline.find_by_name(timeline_name)

  text = "{{timeline(#{timeline.id})}}"
  step %Q{I fill in "#{text}" for "#{container}"}
end

When /^(.*) for the color "([^"]*)"$/ do |step_name, color_name|
  color = Timelines::Color.find_by_name(color_name)

  step %Q{#{step_name} within "#color-#{color.id} td:first-child"}
end
