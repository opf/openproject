Then /^I should see membership to the project "(.+)" with the roles:$/ do |project, roles_table|
  project = Project.like(project).first
  steps %Q{ Then I should see "#{project.name}" within "#tab-content-memberships .memberships" }

  found_roles = page.find(:css, "#tab-content-memberships .memberships").find(:xpath, "//tr[contains(.,'#{project.name}')]").find(:css, "td.roles span").text.split(",").map(&:strip)

  found_roles.should =~ roles_table.raw.flatten
end

Then /^I should not see membership to the project "(.+)"$/ do |project|
  project = Project.like(project).first
  begin 
    page.find(:css, "#tab-content-memberships .memberships")
    steps %Q{ Then I should not see "#{project.name}" within "#tab-content-memberships .memberships" }
  rescue Capybara::ElementNotFound
    steps %Q{ Then I should see "No data to display" within "#tab-content-memberships" }
  end
end

Then /^I check the role "(.+)"$/ do |role|
  role = Role.like(role).first
  steps %Q{And I check "membership_role_ids_#{role.id}"}
end

When /^I delete membership to project "(.*?)"$/ do |project|
  project = Project.like(project).first
  page.find(:css, "#tab-content-memberships .memberships").find(:xpath, "//tr[contains(.,'#{project.name}')]").find(:css, ".icon-del").click
end

When /^I edit membership to project "(.*?)" to contain the roles:$/ do |project, roles_table|
  project = Project.like(project).first
  steps %Q{ Then I should see "#{project.name}" within "#tab-content-memberships .memberships" }

  # Click 'Edit'
  page.find(:css, "#tab-content-memberships .memberships").find(:xpath, "//tr[contains(.,'#{project.name}')]").find(:css, ".icon-edit").click

  roles_table.raw.flatten.map {|r| Role.like(r).first}.each do |role|
    checkbox = page.find(:css, "#tab-content-memberships .memberships").find(:xpath, "//tr[contains(.,'#{project.name}')]//input[@type='checkbox'][@value='#{role.id}']")
    checkbox.click unless checkbox.checked?
  end
  steps %Q{ And I click "Change" within "#tab-content-memberships .memberships" }
end