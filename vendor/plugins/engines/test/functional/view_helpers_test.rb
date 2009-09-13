require File.dirname(__FILE__) + '/../test_helper'

class ViewHelpersTest < ActionController::TestCase
  tests AssetsController
  
  def setup
    get :index
  end
  
  def test_plugin_javascript_helpers
    base_selector = "script[type='text/javascript']"
    js_dir = "/plugin_assets/test_assets/javascripts"
    assert_select "#{base_selector}[src='#{js_dir}/file.1.js']"
    assert_select "#{base_selector}[src='#{js_dir}/file2.js']"
  end

  def test_plugin_stylesheet_helpers
    base_selector = "link[media='screen'][rel='stylesheet'][type='text/css']"
    css_dir = "/plugin_assets/test_assets/stylesheets"
    assert_select "#{base_selector}[href='#{css_dir}/file.1.css']"
    assert_select "#{base_selector}[href='#{css_dir}/file2.css']"
  end

  def test_plugin_image_helpers
    assert_select "img[src='/plugin_assets/test_assets/images/image.png'][alt='Image']"
  end

  def test_plugin_layouts
    get :index
    assert_select "div[id='assets_layout']"
  end  

  def test_plugin_image_submit_helpers
    assert_select "input[src='/plugin_assets/test_assets/images/image.png'][type='image']"
  end

end
