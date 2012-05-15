require 'redmine'

Redmine::Plugin.register :chiliproject_my_project_page do
  name 'My Project Page Plugin'
  author 'Tim Felgentreff @ finnlabs'
  author_url 'http://finn.de/team/#t.felgentreff'
  description 'This plugin replaces the old overview page for projects with something similar to the "My Page"'
  version MyProjectPage::Version.full

  Redmine::AccessControl.permission(:view_project).actions << "my_projects_overviews/index"
  Redmine::AccessControl.permission(:edit_project).actions << "my_projects_overviews/page_layout" <<
                                                              "my_projects_overviews/add_block" <<
                                                              "my_projects_overviews/remove_block" <<
                                                              "my_projects_overviews/update_custom_element" <<
                                                              "my_projects_overviews/order_blocks" <<
                                                              "my_projects_overviews/destroy_attachment"

end
