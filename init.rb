require 'redmine'

Redmine::Plugin.register :redmine_meeting do
  name 'Redmine Meeting'
  author 'Felix Schäfer'
  author_url 'http://finn.de/team'
  description 'This plugin adds a meeting module with functionality to plan and save the minutes of a meeting.'
  url 'http://finn.de'
  version '0.0.1'
  
  requires_redmine :version_or_higher => '0.9'
end
