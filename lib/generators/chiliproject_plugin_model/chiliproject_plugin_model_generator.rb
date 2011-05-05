require 'rails_generator/base'
require 'rails_generator/generators/components/model/model_generator'

class ChiliprojectPluginModelGenerator < ModelGenerator
  attr_accessor :plugin_path, :plugin_name, :plugin_pretty_name
  
  def initialize(runtime_args, runtime_options = {})
    runtime_args = runtime_args.dup
    usage if runtime_args.empty?
    @plugin_name = "chiliproject_" + runtime_args.shift.underscore
    @plugin_pretty_name = plugin_name.titleize
    @plugin_path = "vendor/plugins/#{plugin_name}"
    super(runtime_args, runtime_options)
  end
  
  def destination_root
    File.join(RAILS_ROOT, plugin_path)
  end
  
  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions class_path, class_name, "#{class_name}Test"

      # Model, test, and fixture directories.
      m.directory File.join('app/models', class_path)
      m.directory File.join('test/unit', class_path)
      m.directory File.join('test/fixtures', class_path)

      # Model class, unit test, and fixtures.
      m.template 'model.rb.erb',      File.join('app/models', class_path, "#{file_name}.rb")
      m.template 'unit_test.rb.erb',  File.join('test/unit', class_path, "#{file_name}_test.rb")

      unless options[:skip_fixture] 
       	m.template 'fixtures.yml',  File.join('test/fixtures', "#{table_name}.yml")
      end

      unless options[:skip_migration]
        m.migration_template 'migration.rb.erb', 'db/migrate', :assigns => {
          :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}"
        }, :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
      end
    end
  end
end
