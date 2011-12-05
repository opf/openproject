require 'redmine'

Redmine::Plugin.register :redmine_additional_formats do
  name 'Redmine Additional Formats plugin'
  author 'Holger Just, Tim Felgentreff @ finnlabs'
  author_url 'http://finn.de/team#h.just'
  description 'This plugin provides additional formats for exporting, like a printable view for issue lists and an excel builder for issue exports'
  version '0.3.0'

  requires_redmine :version_or_higher => '0.9'
  requires_redmine_plugin :redmine_reporting, :version_or_higher => '0.1'

  Redmine::AccessControl.permission(:view_issues).actions << "issues/printable"
end

require 'dispatcher'
Dispatcher.to_prepare do
  # Controller Patches
  require_dependency 'printable_issues/issues_controller_patch'
  require_dependency 'xls_report/issues_controller_patch'
  require_dependency 'xls_report/cost_reports_controller_patch'

  # Initialization
  Mime::Type.register('application/vnd.ms-excel', :xls, %w(application/vnd.ms-excel)) unless defined? Mime::XLS
end

# Hooks
require 'additional_formats/filename_helper'
require 'printable_issues/issue_hook'
require 'xls_report/issue_hook'
require 'xls_report/cost_report_hook'
