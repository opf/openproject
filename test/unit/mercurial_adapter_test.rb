require File.dirname(__FILE__) + '/../test_helper'
begin
  require 'mocha'
  
  class MercurialAdapterTest < Test::Unit::TestCase
    
    TEMPLATES_DIR = "#{RAILS_ROOT}/extra/mercurial"
    TEMPLATE_NAME = "hg-template"
    TEMPLATE_EXTENSION = "tmpl"
    
    REPOSITORY_PATH = RAILS_ROOT.gsub(%r{config\/\.\.}, '') + '/tmp/test/mercurial_repository'
    
    
    def test_version_template_0_9_5
      # 0.9.5
      test_version_template_for("0.9.5", [0,9,5], "0.9.5")
    end
    
    def test_version_template_1_0
      # 1.0
      test_version_template_for("1.0", [1,0], "1.0")
    end
    
    def test_version_template_1_0_win
      test_version_template_for("1e4ddc9ac9f7+20080325", "Unknown version", "1.0")
    end
    
    def test_version_template_1_0_1_win
      test_version_template_for("1.0.1+20080525", [1,0,1], "1.0")
    end
    
    def test_version_template_changeset_id
      test_version_template_for("1916e629a29d", "Unknown version", "1.0")
    end
    
    private
    
    def test_version_template_for(hgversion, version, templateversion)
      Redmine::Scm::Adapters::MercurialAdapter.any_instance.stubs(:hgversion_from_command_line).returns(hgversion)
      adapter = Redmine::Scm::Adapters::MercurialAdapter.new(REPOSITORY_PATH)
      assert_equal version, adapter.hgversion
      assert_equal "#{TEMPLATES_DIR}/#{TEMPLATE_NAME}-#{templateversion}.#{TEMPLATE_EXTENSION}", adapter.template_path
      assert File.exist?(adapter.template_path)
    end
  end
  
rescue LoadError
  def test_fake; assert(false, "Requires mocha to run those tests")  end
end
