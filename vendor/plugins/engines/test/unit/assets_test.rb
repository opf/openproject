require File.dirname(__FILE__) + '/../test_helper'

class AssetsTest < Test::Unit::TestCase  
  def setup
    Engines::Assets.mirror_files_for Engines.plugins[:test_assets]
  end
  
  def teardown
    FileUtils.rm_r(Engines.public_directory) if File.exist?(Engines.public_directory)
  end
  
  def test_engines_has_created_base_public_file
    assert File.exist?(Engines.public_directory)
  end
  
  def test_engines_has_created_README_in_public_directory
    assert File.exist?(File.join(Engines.public_directory, 'README'))
  end
  
  def test_public_files_have_been_copied_from_test_assets_plugin
    assert File.exist?(File.join(Engines.public_directory, 'test_assets'))
    assert File.exist?(File.join(Engines.public_directory, 'test_assets', 'file.txt'))
    assert File.exist?(File.join(Engines.public_directory, 'test_assets', 'subfolder'))
    assert File.exist?(File.join(Engines.public_directory, 'test_assets', 'subfolder', 'file_in_subfolder.txt'))
  end
  
  def test_engines_has_not_created_duplicated_file_structure
    assert !File.exists?(File.join(Engines.public_directory, "test_assets", RAILS_ROOT))
  end
  
  def test_public_files_have_been_copied_from_test_assets_with_assets_dir_plugin
    Engines::Assets.mirror_files_for Engines.plugins[:test_assets_with_assets_directory]

    assert File.exist?(File.join(Engines.public_directory, 'test_assets_with_assets_directory'))
    assert File.exist?(File.join(Engines.public_directory, 'test_assets_with_assets_directory', 'file.txt'))
    assert File.exist?(File.join(Engines.public_directory, 'test_assets_with_assets_directory', 'subfolder'))
    assert File.exist?(File.join(Engines.public_directory, 'test_assets_with_assets_directory', 'subfolder', 'file_in_subfolder.txt'))
  end
  
  def test_public_files_have_been_copied_from_test_assets_with_no_subdirectory_plugin
    Engines::Assets.mirror_files_for Engines.plugins[:test_assets_with_no_subdirectory]

    assert File.exist?(File.join(Engines.public_directory, 'test_assets_with_no_subdirectory'))
    assert File.exist?(File.join(Engines.public_directory, 'test_assets_with_no_subdirectory', 'file.txt'))    
  end
  
  def test_public_files_have_NOT_been_copied_from_plugins_without_public_or_asset_directories
    Engines::Assets.mirror_files_for Engines.plugins[:alpha_plugin]
    
    assert !File.exist?(File.join(Engines.public_directory, 'alpha_plugin'))
  end
end