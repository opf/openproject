#-- encoding: UTF-8
# Tests in this file ensure that:
#
# * translations in the application take precedence over those in plugins
# * translations in subsequently loaded plugins take precendence over those in previously loaded plugins

require File.dirname(__FILE__) + '/../test_helper'

class LocaleLoadingTest < ActionController::TestCase
  def setup
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # app takes precedence over plugins
	
  def test_WITH_a_translation_defined_in_both_app_and_plugin_IT_should_find_the_one_in_app
    assert_equal I18n.t('hello'), 'Hello world'
  end
	
  # subsequently loaded plugins take precendence over previously loaded plugins
	
  def test_WITH_a_translation_defined_in_two_plugins_IT_should_find_the_latter_of_both
    assert_equal I18n.t('plugin'), 'beta'
  end
end
	
