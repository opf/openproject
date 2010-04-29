require 'redmine'

Redmine::Plugin.register :redmine_reporting do
  name 'Reporting Plugin'
  author 'Konstantin Haase, Philipp Tessenow @ finnlabs'
  author_url 'http://finn.de/team'
  description 'The reporting plugin provides extended reporting functionality for Redmine including Cost Reports.'
  version '0.1'

  requires_redmine :version_or_higher => '0.9'
  requires_redmine_plugin :redmine_costs, :version_or_higher => '0.3'
end
