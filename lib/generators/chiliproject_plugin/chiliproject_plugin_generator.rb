class ChiliprojectPluginGenerator < Rails::Generator::NamedBase
  attr_reader :plugin_path, :plugin_name, :plugin_pretty_name
  
  def initialize(runtime_args, runtime_options = {})
    super
    @plugin_name = "chiliproject_#{file_name.underscore}"
    @plugin_pretty_name = plugin_name.titleize
    @plugin_path = "vendor/plugins/#{plugin_name}"
  end
  
  def manifest
    record do |m|
      m.directory "#{plugin_path}/app/controllers"
      m.directory "#{plugin_path}/app/helpers"
      m.directory "#{plugin_path}/app/models"
      m.directory "#{plugin_path}/app/views"
      m.directory "#{plugin_path}/db/migrate"
      m.directory "#{plugin_path}/lib/tasks"
      m.directory "#{plugin_path}/assets/images"
      m.directory "#{plugin_path}/assets/javascripts"
      m.directory "#{plugin_path}/assets/stylesheets"
      m.directory "#{plugin_path}/lang"
      m.directory "#{plugin_path}/config/locales"
      m.directory "#{plugin_path}/test"
      
      m.template 'README.rdoc',    "#{plugin_path}/README.rdoc"
      m.template 'init.rb.erb',   "#{plugin_path}/init.rb"
      m.template 'en.yml',    "#{plugin_path}/lang/en.yml"
      m.template 'en_rails_i18n.yml',    "#{plugin_path}/config/locales/en.yml"
      m.template 'test_helper.rb.erb',    "#{plugin_path}/test/test_helper.rb"
    end
  end
end
