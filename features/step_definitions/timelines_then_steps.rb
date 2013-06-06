#encoding: utf-8
Then /^the "([^"]*)" row should (not )?be marked as default$/ do |title, negation|
  should_be_visible = !negation

  table_row = find_field(title).find(:xpath, "./ancestor::tr")

  # The first column contains the Default value
  # TODO: This should not be a magic constant but derived from the actual table
  # header.
  if should_be_visible
    table_row.should have_css('td:nth-child(1) img[alt=checked]')
  else
    table_row.should_not have_css('td:nth-child(1) img[alt=checked]')
  end
end

Then /^I should see that "([^"]*)" is( not)? a milestone and( not)? shown in aggregation$/ do |name, not_milestone, not_in_aggregation|
  row = page.find(:css, ".timelines-pet-name", :text => Regexp.new("^#{name}$")).find(:xpath, './ancestor::tr')

  nodes = row.all(:css, '.timelines-pet-is_milestone img[alt=checked]')
  if not_milestone
    nodes.should be_empty
  else
    nodes.should_not be_empty
  end

  nodes = row.all(:css, '.timelines-pet-in_aggregation img[alt=checked]')
  if not_in_aggregation
    nodes.should be_empty
  else
    nodes.should_not be_empty
  end
end

Then /^the "([^"]*)" row should (not )?be marked as allowing associations$/ do |title, negation|
  should_be_visible = !negation

  table_row = page.all(:css, "table.list tbody tr td", :text => title).first.find(:xpath, "./ancestor::tr")
  nodes = table_row.all(:css, '.timelines-pt-allows_association img[alt=checked]')
  if should_be_visible
    nodes.should_not be_empty
  else
    nodes.should be_empty
  end
end

Then /^I should see that "([^"]*)" is a color$/ do |name|
  cell = page.all(:css, ".timelines-color-name", :text => name)
  cell.should_not be_empty
end

Then /^I should not see the "([^"]*)" planning element type$/ do |name|
  page.all(:css, '.timelines-pet-name', :text => name).should be_empty
end

Then /^I should not see the "([^"]*)" color$/ do |name|
  cell = page.all(:css, ".timelines-color-name", :text => name)
  cell.should be_empty
end

Then /^"([^"]*)" should be the first element in the list$/ do |name|
  cell = page.all(:css, "table.list tbody tr:first-child td", :text => name)
  cell.should_not be_empty
end

Then /^"([^"]*)" should be the last element in the list$/ do |name|
  has_css?("table.list tbody tr td", :text => Regexp.new("^#{name}$"))
end

Then /^I should see an? (notice|warning|error) flash stating "([^"]*)"$/ do |class_name, message|
  page.all(:css, ".flash.#{class_name}, .flash.#{class_name} *", :text => message).should_not be_empty
end

Then /^I should see an error explanation stating "([^"]*)"$/ do |message|
  page.all(:css, ".errorExplanation li, .errorExplanation li *", :text => message).should_not be_empty
end

Then /^I should see a planning element named "([^"]*)"$/ do |name|
  cells = page.all(:css, "table td.timelines-pe-name *", :text => name)
  cells.should_not be_empty
end

Then /^I should( not)? see "([^"]*)" below "([^"]*)"$/ do |negation, text, heading|
  cells = page.all(:css, "h1, h2, h3, h4, h5, h6", :text => heading)
  cells.should_not be_empty

  container = cells.first.find(:xpath, "./ancestor::*[@class='container']")

  if negation
    container.should be_has_no_content(text)
  else
    container.should be_has_content(text)
  end
end

Then /^I should not be able to add new project associations$/ do
  link = page.all(:css, "a.timelines-new-project-associations")
  link.should be_empty
end

Then /^I should (not )?see a planning element link for "([^"]*)"$/ do |negate, planning_element_name|
  planning_element = Timelines::PlanningElement.find_by_name(planning_element_name)
  text = "*#{planning_element.id}"

  step %Q{I should #{negate}see "#{text}"}
end

Then /^I should (not )?see a planning element quickinfo link for "([^"]*)"$/ do |negate, planning_element_name|
  planning_element = Timelines::PlanningElement.find_by_name(planning_element_name)


  text = "*#{planning_element.id} #{planning_element.planning_element_status.nil? ? "" : planning_element.planning_element_status.name + ":"} #{planning_element.name} #{planning_element.start_date.to_s} – #{planning_element.end_date.to_s} (#{planning_element.responsible.to_s})"
  step %Q{I should #{negate}see "#{text}"}
end

Then /^I should (not )?see a planning element quickinfo link with description for "([^"]*)"$/ do |negate, planning_element_name|
  planning_element = Timelines::PlanningElement.find_by_name(planning_element_name)

  step %Q{I should #{negate}see a planning element quickinfo link for "#{planning_element_name}"}
  step %Q{I should #{negate}see "#{planning_element.description}"}
end

Then /^I should (not )?see the timeline "([^"]*)"$/ do |negate, timeline_name|
  selector = "div.timeline div.tl-left-main"
  timeline = Timelines::Timeline.find_by_name(timeline_name)

  if (negate && page.has_css?(selector)) || !negate
    timeline.project.timelines_planning_elements.each do |planning_element|
      step %Q{I should #{negate}see "#{planning_element.name}" within "#{selector}"}
    end
  end
end
