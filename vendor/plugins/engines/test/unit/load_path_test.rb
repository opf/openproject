#-- encoding: UTF-8
# Tests in this file ensure that:
#
# * the application /app/[controllers|helpers|models] and /lib 
#   paths preceed the corresponding plugin paths
# * the plugin paths are added to $LOAD_PATH in the order in which plugins are 
#   loaded

require File.dirname(__FILE__) + '/../test_helper'

class LoadPathTest < Test::Unit::TestCase
  def setup
    @load_path = expand_paths($LOAD_PATH)
  end
  
  # Not sure if these test actually make sense as this now essentially tests
  # Rails core functionality. On the other hand Engines relies on this to some
  # extend so this will choke if something important changes in Rails.
  
  # the application app/... and lib/ directories should appear
  # before any plugin directories
  
  def test_application_app_libs_should_precede_all_plugin_app_libs
    types = %w(app/controllers app/helpers app/models lib)
    types.each do |t|
      app_index = load_path_index(File.join(RAILS_ROOT, t))
      assert_not_nil app_index, "#{t} is missing in $LOAD_PATH"
      Engines.plugins.each do |plugin|
        first_plugin_index = load_path_index(File.join(plugin.directory, t))
        assert(app_index < first_plugin_index) unless first_plugin_index.nil?
      end
    end
  end
  
  # the engine directories should appear in the proper order based on
  # the order they were started  
  
  def test_plugin_dirs_should_appear_in_reverse_plugin_loading_order
    app_paths = %w(app/controllers/ app app/models app/helpers lib)
    app_paths.map { |p| File.join(RAILS_ROOT, p)}
    plugin_paths = Engines.plugins.reverse.collect { |plugin| plugin.load_paths.reverse }.flatten    
    
    expected_paths = expand_paths(app_paths + plugin_paths)    
    # only look at those paths that are also present in expected_paths so
    # the only difference would be in the order of the paths
    actual_paths = @load_path & expected_paths 
    
    assert_equal expected_paths, actual_paths
  end
  
  protected    
    def expand_paths(paths)
      paths.collect { |p| File.expand_path(p) }
    end
    
    def load_path_index(dir)
      @load_path.index(File.expand_path(dir))
    end  
end