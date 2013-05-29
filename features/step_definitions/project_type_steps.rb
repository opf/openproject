When /^I follow the edit link of the project type "([^"]*)"$/ do |project_type_name|
  type = ProjectType.find_by_name(project_type_name)

  href = Rails.application.routes.url_helpers.edit_project_type_path(type)

  click_link(type.name, :href => href)
end
