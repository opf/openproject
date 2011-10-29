#-- encoding: UTF-8
class AppAndPluginLibModel < ActiveRecord::Base
  def self.report_location; TestHelper::report_location(__FILE__); end

  def defined_only_in_alpha_plugin_version
    # should not be defined
  end
end