Given(/^there is a board "(.*?)" for project "(.*?)"$/) do |board_name, project_identifier|
  FactoryGirl.create :board, :project => get_project(project_identifier), :name => board_name
end
