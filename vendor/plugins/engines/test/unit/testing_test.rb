#-- encoding: UTF-8
require File.dirname(__FILE__) + '/../test_helper'

class TestingTest < Test::Unit::TestCase
  def setup
    Engines::Testing.set_fixture_path
    @filename = File.join(Engines::Testing.temporary_fixtures_directory, 'testing_fixtures.yml')
    File.delete(@filename) if File.exists?(@filename)
  end
  
  def teardown
    File.delete(@filename) if File.exists?(@filename)
    if File.directory?(Engines::Testing.temporary_fixtures_directory)
      FileUtils.rm_r(Engines::Testing.temporary_fixtures_directory)
    end
  end

  def test_should_copy_fixtures_files_to_tmp_directory
    assert !File.exists?(@filename)
    Engines::Testing.setup_plugin_fixtures
    assert File.exists?(@filename)
  end

  def test_creates_temporary_fixtures_directory
    assert File.directory?(Engines::Testing.temporary_fixtures_directory)
  end

  def test_set_fixture_path_doesnt_break_load_path
    assert_nothing_raised "require has failed after call to Engines::Testing.set_fixture_path" do
      require 'tmpdir' # XXX this can be anything, even loaded file
    end
  end

  def test_fixtures_are_in_load_path
    assert $LOAD_PATH.include?(Engines::Testing.temporary_fixtures_directory)
  end
end
