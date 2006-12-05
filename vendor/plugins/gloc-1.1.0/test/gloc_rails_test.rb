# Copyright (c) 2005-2006 David Barri

$LOAD_PATH.push File.join(File.dirname(__FILE__),'..','lib')
require "#{File.dirname(__FILE__)}/../../../../test/test_helper"
require "#{File.dirname(__FILE__)}/../init"

class GLocRailsTestController < ActionController::Base
  autodetect_language_filter :only => :auto, :on_set_lang => :called_when_set, :on_no_lang => :called_when_bad
  autodetect_language_filter :only => :auto2, :check_accept_header => false, :check_params => 'xx'
  autodetect_language_filter :only => :auto3, :check_cookie => false
  autodetect_language_filter :only => :auto4, :check_cookie => 'qwe', :check_params => false
  def rescue_action(e) raise e end
  def auto; render :text => 'auto'; end
  def auto2; render :text => 'auto'; end
  def auto3; render :text => 'auto'; end
  def auto4; render :text => 'auto'; end
  attr_accessor :callback_set, :callback_bad
  def called_when_set(l) @callback_set ||= 0; @callback_set += 1 end
  def called_when_bad; @callback_bad ||= 0; @callback_bad += 1 end
end

class GLocRailsTest < Test::Unit::TestCase
  
  def setup
    @lstrings = GLoc::LOCALIZED_STRINGS.clone
    @old_config= GLoc::CONFIG.clone
    begin_new_request
  end

  def teardown
    GLoc.clear_strings
    GLoc::LOCALIZED_STRINGS.merge! @lstrings
    GLoc::CONFIG.merge! @old_config
  end
  
  def begin_new_request
    @controller = GLocRailsTestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_autodetect_language
    GLoc::CONFIG[:default_language]= :def
    GLoc::CONFIG[:default_param_name] = 'plang'
    GLoc::CONFIG[:default_cookie_name] = 'clang'
    GLoc.clear_strings
    GLoc.add_localized_strings :en, :a => 'a'
    GLoc.add_localized_strings :en_au, :a => 'a'
    GLoc.add_localized_strings :en_US, :a => 'a'
    GLoc.add_localized_strings :Ja, :a => 'a'
    GLoc.add_localized_strings :ZH_HK, :a => 'a'

    # default
    subtest_autodetect_language :def, nil, nil, nil
    subtest_autodetect_language :def, 'its', 'all', 'bullshit,man;q=zxc'
    # simple
    subtest_autodetect_language :en_au, 'en_au', nil, nil
    subtest_autodetect_language :en_US, nil, 'en_us', nil
    subtest_autodetect_language :Ja, nil, nil, 'ja'
    # priority
    subtest_autodetect_language :Ja, 'ja', 'en_us', 'qwe_ja,zh,monkey_en;q=0.5'
    subtest_autodetect_language :en_US, 'why', 'en_us', 'qwe_ja,zh,monkey_en;q=0.5'
    subtest_autodetect_language :Ja, nil, nil, 'qwe_en,JA,zh,monkey_en;q=0.5'
    # dashes to underscores in accept string
    subtest_autodetect_language :en_au, 'monkey', nil, 'de,EN-Au'
    # remove dialect
    subtest_autodetect_language :en, nil, 'en-bullshit', nil
    subtest_autodetect_language :en, 'monkey', nil, 'de,EN-NZ,ja'
    # different dialect
    subtest_autodetect_language :ZH_HK, 'zh', nil, 'de,EN-NZ,ja'
    subtest_autodetect_language :ZH_HK, 'monkey', 'zh', 'de,EN-NZ,ja'
    
    # Check param/cookie names use defaults
    GLoc::CONFIG[:default_param_name] = 'p_lang'
    GLoc::CONFIG[:default_cookie_name] = 'c_lang'
    # :check_params
    subtest_autodetect_language :def, 'en_au', nil, nil
    subtest_autodetect_language :en_au, {:p_lang => 'en_au'}, nil, nil
    # :check_cookie
    subtest_autodetect_language :def, nil, 'en_us', nil
    subtest_autodetect_language :en_US, nil, {:c_lang => 'en_us'}, nil
    GLoc::CONFIG[:default_param_name] = 'plang'
    GLoc::CONFIG[:default_cookie_name] = 'clang'

    # autodetect_language_filter :only => :auto2, :check_accept_header => false, :check_params => 'xx'
    subtest_autodetect_language :def, 'ja', nil, 'en_US', :auto2
    subtest_autodetect_language :Ja, {:xx => 'ja'}, nil, 'en_US', :auto2
    subtest_autodetect_language :en_au, 'ja', 'en_au', 'en_US', :auto2
    
    # autodetect_language_filter :only => :auto3, :check_cookie => false
    subtest_autodetect_language :Ja, 'ja', 'en_us', 'qwe_ja,zh,monkey_en;q=0.5', :auto3
    subtest_autodetect_language :ZH_HK, 'hehe', 'en_us', 'qwe_ja,zh,monkey_en;q=0.5', :auto3
    
    # autodetect_language_filter :only => :auto4, :check_cookie => 'qwe', :check_params => false
    subtest_autodetect_language :def, 'ja', 'en_us', nil, :auto4
    subtest_autodetect_language :ZH_HK, 'ja', 'en_us', 'qwe_ja,zh,monkey_en;q=0.5', :auto4
    subtest_autodetect_language :en_US, 'ja', {:qwe => 'en_us'}, 'ja', :auto4
  end

  def subtest_autodetect_language(expected,params,cookie,accept, action=:auto)
    begin_new_request
    params= {'plang' => params} if params.is_a?(String)
    params ||= {}
    if cookie
      cookie={'clang' => cookie} unless cookie.is_a?(Hash)
      cookie.each_pair {|k,v| @request.cookies[k.to_s]= CGI::Cookie.new(k.to_s,v)}
    end
    @request.env['HTTP_ACCEPT_LANGUAGE']= accept
    get action, params
    assert_equal expected, @controller.current_language
    if action == :auto
      s,b = expected != :def ? [1,nil] : [nil,1]
      assert_equal s, @controller.callback_set
      assert_equal b, @controller.callback_bad
    end
  end
  
end