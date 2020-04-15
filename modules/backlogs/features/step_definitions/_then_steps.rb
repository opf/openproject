#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

Then /^(.+) should be in the (\d+)(?:st|nd|rd|th) position of the sprint named (.+)$/ do |story_subject, position, sprint_name|
  position = position.to_i
  story = Story.where(subject: story_subject, versions: { name: sprint_name }).joins(:version).first
  story_position(story).should == position.to_i
end

Then /^I should see (\d+) (?:product )?owner backlogs$/ do |count|
  sprint_backlogs = page.all(:css, '#owner_backlogs_container .sprint')
  sprint_backlogs.length.should == count.to_i
end

Then /^I should see (\d+) sprint backlogs$/ do |count|
  sprint_backlogs = page.all(:css, '#sprint_backlogs_container .sprint')
  sprint_backlogs.length.should == count.to_i
end

Then /^I should see the burndown chart for sprint "(.+?)"$/ do |sprint|
  sprint = Sprint.find_by(name: sprint)

  page.should have_css("#burndown_#{sprint.id}")
end

Then /^I should see the WorkPackages page$/ do
  page.should have_css('.workpackages-table')
end

Then /^I should see the taskboard$/ do
  page.should have_css('#taskboard')
end

Then /^I should see the product backlog$/ do
  page.should have_css('#owner_backlogs_container')
end

Then /^I should see (\d+) stories in (?:the )?"(.+?)"$/ do |count, backlog_name|
  sprint = Sprint.find_by(name: backlog_name)
  page.all(:css, "#backlog_#{sprint.id} .story").size.should == count.to_i
end

Then /^the velocity of "(.+?)" should be "(.+?)"$/ do |backlog_name, velocity|
  sprint = Sprint.find_by(name: backlog_name)
  page.find(:css, "#backlog_#{sprint.id} .velocity").text.should == velocity
end

Then /^show me the list of sprints$/ do
  sprints = Sprint.where(project_id: @project.id)

  puts "\n"
  puts "\t| #{'id'.ljust(3)} | #{'name'.ljust(18)} | #{'start_date'.ljust(18)} | #{'effective_date'.ljust(18)} | #{'updated_on'.ljust(20)}"
  sprints.each do |sprint|
    puts "\t| #{sprint.id.to_s.ljust(3)} | #{sprint.name.to_s.ljust(18)} | #{sprint.start_date.to_s.ljust(18)} | #{sprint.effective_date.to_s.ljust(18)} | #{sprint.updated_on.to_s.ljust(20)} |"
  end
  puts "\n\n"
end

Then /^show me the list of stories$/ do
  stories = Story.where(project_id: @project.id).order(Arel.sql('position ASC'))
  subject_max = (stories.map(&:subject) << 'subject').sort { |a, b| a.length <=> b.length }.last.length
  sprints = @project.versions
  sprint_max = (sprints.map(&:name) << 'sprint').sort { |a, b| a.length <=> b.length }.last.length

  puts "\n"
  puts "\t| #{'id'.ljust(5)} | #{'position'.ljust(8)} | #{'status'.ljust(12)} | #{'rank'.ljust(4)} | #{'subject'.ljust(subject_max)} | #{'sprint'.ljust(sprint_max)} |"
  stories.each do |story|
    puts "\t| #{story.id.to_s.ljust(5)} | #{story.position.to_s.ljust(8)} | #{story.status.name[0, 12].ljust(12)} | #{story.rank.to_s.ljust(4)} | #{story.subject.ljust(subject_max)} | #{(story.version_id.nil? ? Sprint.new : Sprint.find(story.version_id)).name.ljust(sprint_max)} |"
  end
  puts "\n\n"
end

Then /^(.+) should be the higher (story|item|task) of (.+)$/ do |higher_subject, type, lower_subject|
  work_package_class = (type == 'task') ? Task : Story

  higher = work_package_class.where(subject: higher_subject)
  higher.length.should == 1

  lower = work_package_class.where(subject: lower_subject)
  lower.length.should == 1

  lower.first.higher_item.id.should == higher.first.id
end

Then /^the request should complete successfully$/ do
  page.driver.response.status.should == 200
end

Then /^the request should fail$/ do
  page.driver.response.status.should == 401
end

Then /^the (\d+)(?:st|nd|rd|th) story in (?:the )?"(.+?)" should be "(.+)"$/ do |position, version_name, subject|
  sleep 2
  version = Version.find_by(name: version_name)
  story = Story.at_rank(@project.id, version.id, position.to_i)
  story.should_not be_nil
  story.subject.should == subject
end

Then /^the (\d+)(?:st|nd|rd|th) story in (?:the )?"(.+?)" should be in the "(.+?)" type$/ do |position, version_name, type_name|
  version = Version.find_by(name: version_name)
  type = Type.find_by(name: type_name)
  story = Story.at_rank(@project.id, version.id, position.to_i)
  story.should_not be_nil
  story.type.should == type
end

Then /^the (\d+)(?:st|nd|rd|th) story in (?:the )?"(.+?)" should have the ID of "(.+?)"$/ do |position, version_name, subject|
  version = Version.find_by(name: version_name)
  actual_story = WorkPackage.find_by(subject: subject, version_id: version.id)
  step %%I should see "#{actual_story.id}" within "#backlog_#{version.id} .story:nth-child(#{position}) .id div.t"%
end

Then /^all positions should be unique for each version$/ do
  Story.find_by_sql("select project_id, version_id, position, count(*) as dups from #{WorkPackage.table_name} where not position is NULL group by project_id, version_id, position having count(*) > 1").length.should == 0
end

Then /^the (\d+)(?:st|nd|rd|th) task for (.+) should be (.+)$/ do |position, story_subject, task_subject|
  story = Story.find_by(subject: story_subject)
  expect(story.children.order(position: :asc)[position.to_i - 1].subject)
    .to eql(task_subject)
end

Then /^the server should return an update error$/ do
  page.driver.response.status.should == 400
end

Then /^the server should return (\d+) updated (.+)$/ do |count, object_type|
  page.all("##{object_type.pluralize} .#{object_type.singularize}").length.should == count.to_i
end

Then /^the sprint named (.+) should have (\d+) impediments? named (.+)$/ do |sprint_name, count, impediment_subject|
  sprints = Sprint.where(name: sprint_name)
  sprints.length.should == 1

  sprints.first.impediments.map { |i| i.subject == impediment_subject }.length.should == count.to_i
end

Then /^the impediment "(.+)" should signal( | un)successful saving$/ do |impediment_subject, negative|
  pos_or_neg_should = !negative.blank? ? :should : :should_not

  page.send(pos_or_neg_should, have_selector('div.impediment.error', text: impediment_subject))
end

Then /^the sprint should be updated accordingly$/ do
  sprint = Sprint.find(@sprint_params['id'])

  sprint.attributes.each_key do |key|
    unless ['updated_on', 'created_on'].include?(key)
      (key.include?('_date') ? sprint[key].strftime('%Y-%m-%d') : sprint[key]).should == @sprint_params[key]
    end
  end
end

Then /^the status of the story should be set as (.+)$/ do |status|
  @story.reload
  @story.status.name.downcase.should == status
end

Then /^the story named (.+) should have 1 task named (.+)$/ do |story_subject, task_subject|
  stories = Story.where(subject: story_subject)
  stories.length.should == 1

  tasks = Task
          .children_of(stories.first)
          .where(subject: task_subject)
  tasks.length.should == 1
end

Then /^the story should be at the (top|bottom)$/ do |position|
  if position == 'top'
    story_position(@story).should == 1
  else
    story_position(@story).should == @story_ids.length
  end
end

Then /^the story should be at position (.+)$/ do |position|
  story_position(@story).should == position.to_i
end

Then /^the story should have a (.+) of (.+)$/ do |attribute, value|
  @story.reload
  if attribute == 'type'
    attribute = 'type_id'
    value = Type.find_by(name: value).id
  end
  @story[attribute].should == value
end

Then /^the wiki page (.+) should contain (.+)$/ do |title, content|
  page = @project.wiki.find_page(title)
  page.should_not be_nil

  raise "\"#{content}\" not found on page \"#{title}\"" unless page.content.text.match(/#{content}/)
end

Then /^(work_package|task|story) (.+) should have (.+) set to (.+)$/ do |_type, subject, attribute, value|
  work_package = WorkPackage.find_by(subject: subject)
  work_package[attribute].should == value.to_i
end

Then /^the error alert should show "(.+?)"$/ do |msg|
  step %{I should see "#{msg}" within "#msgBox"}
end

Then /^the start date of "(.+?)" should be "(.+?)"$/ do |sprint_name, date|
  version = Version.find_by(name: sprint_name)

  step %{I should see "#{date}" within "div#sprint_#{version.id} div.start_date"}
end

Then /^I should see "(.+?)" as a task to story "(.+?)"$/ do |task_name, story_name|
  story = Story.find_by(subject: story_name)

  step %{I should see "#{task_name}" within "tr.story_#{story.id}"}
end

Then /^the (?:work_package|task|story) "(.+?)" should have "(.+?)" as its target version$/ do |task_name, version_name|
  work_package = WorkPackage.find_by(subject: task_name)
  version = Version.find_by(name: version_name)

  work_package.version.should eql version
end

Then /^there should not be a saving error on task "(.+?)"$/ do |task_name|
  elements = all(:xpath, "//*[contains(., \"#{task_name}\")]")
  task_div = elements.find { |e| e.tag_name == 'div' && e[:class].include?('task') }
  task_div[:class].should_not include('error')
end

Then /^I should be notified that the work_package "(.+?)" is an invalid parent to the work_package "(.+?)" because of cross project limitations$/ do |parent_name, child_name|
  step %{I should see "Parent is invalid because the work package '#{child_name}' is a backlog task and therefore cannot have a parent outside of the current project." within "#errorExplanation"}
end

Then /^the PDF download dialog should be displayed$/ do
  # As far as I'm aware there's nothing that can be done here to check for this.
end
