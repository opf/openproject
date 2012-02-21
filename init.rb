require 'redmine'

Redmine::Plugin.register :chiliproject_my_project_page do
  name 'My Project Page Plugin'
  author 'Tim Felgentreff @ finnlabs'
  author_url 'http://finn.de/team/#t.felgentreff'
  description 'This plugin replaces the old overview page for projects with something similar to the "My Page"'
  version MyProjectPage::Version.full
end
