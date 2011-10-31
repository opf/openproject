#-- encoding: UTF-8
class PluginMail < ActionMailer::Base
  def mail_from_plugin(note=nil)
    body(:note => note)
  end
  
  def mail_from_plugin_with_application_template(note=nil)
    body(:note => note)
  end
  
  def multipart_from_plugin
    content_type 'multipart/alternative'
    part :content_type => "text/html", :body => render_message("multipart_from_plugin_html", {})
    part "text/plain" do |p|
      p.body = render_message("multipart_from_plugin_plain", {})
    end
  end
  
  def multipart_from_plugin_with_application_template
    content_type 'multipart/alternative'
    part :content_type => "text/html", :body => render_message("multipart_from_plugin_with_application_template_html", {})
    part "text/plain" do |p|
      p.body = render_message("multipart_from_plugin_with_application_template_plain", {})
    end
  end  
  
end