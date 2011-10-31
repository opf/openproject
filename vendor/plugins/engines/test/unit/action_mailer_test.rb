#-- encoding: UTF-8
require File.dirname(__FILE__) + '/../test_helper'

class ActionMailerWithinApplicationTest < Test::Unit::TestCase
  
  def test_normal_implicit_template
    m = NotifyMail.create_signup("hello")
    assert m.body =~ /^Signup template from application/
  end
  
  def test_action_mailer_can_get_helper
    m = NotifyMail.create_signup('James')
    assert m.body =~ /James/
    assert m.body =~ /semaJ/ # from the helper
  end
  
  def test_multipart_mails_with_explicit_templates
    m = NotifyMail.create_multipart
    assert_equal 2, m.parts.length
    assert_equal 'the html part of the email james', m.parts[0].body
    assert_equal 'the plaintext part of the email', m.parts[1].body
  end
  
  def test_multipart_mails_with_implicit_templates
    m = NotifyMail.create_implicit_multipart
    assert_equal 2, m.parts.length
    assert_equal 'the implicit plaintext part of the email', m.parts[0].body    
    assert_equal 'the implicit html part of the email james', m.parts[1].body
  end
end


class ActionMailerWithinPluginsTest < Test::Unit::TestCase  
  def test_should_be_able_to_create_mails_from_plugin
    m = PluginMail.create_mail_from_plugin("from_plugin")
    assert_equal "from_plugin", m.body
  end
  
  def test_should_be_able_to_overload_views_within_the_application
    m = PluginMail.create_mail_from_plugin_with_application_template("from_plugin")
    assert_equal "from_plugin (from application)", m.body    
  end
  
  def test_should_be_able_to_create_a_multipart_mail_from_within_plugin
    m = PluginMail.create_multipart_from_plugin
    assert_equal 2, m.parts.length
    assert_equal 'html template', m.parts[0].body
    assert_equal 'plain template', m.parts[1].body
  end
  
  def test_plugin_mailer_template_overriding
    m = PluginMail.create_multipart_from_plugin_with_application_template
    assert_equal 'plugin mail template loaded from application', m.parts[1].body
  end
end