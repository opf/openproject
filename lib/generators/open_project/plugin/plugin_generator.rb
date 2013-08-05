class OpenProject::PluginGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :plugin_name, :type => :string, :default => "openproject-new-plugin"
  argument :root_folder, :type => :string, :default => "vendor/gems"

  # every public method is run when the generator is invoked
  def generate_plugin
    plugin_dir
    lib_dir
  end

  def full_name
    @full_name ||= begin
      "openproject-#{plugin_name}"
    end
  end

  private
  def raise_on_params
    puts plugin_name
    puts root_folder
  end

  def plugin_path
    "#{root_folder}/openproject-#{plugin_name}"
  end

  def plugin_dir
    @plugin_dir ||= begin
      directory('', plugin_path, :recursive => false)
    end
  end

  def lib_path
    "#{plugin_path}/lib"
  end

  def lib_dir
    @lib_dir ||= begin
      directory('lib', lib_path)
    end
  end
end
