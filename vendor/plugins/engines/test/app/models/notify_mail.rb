#-- encoding: UTF-8
class NotifyMail < ActionMailer::Base

  helper :mail
  
  def signup(txt)
    body(:name => txt)
  end
  
  def multipart
    recipients 'some_address@email.com'
    subject    'multi part email'
    from       "another_user@email.com"
    content_type 'multipart/alternative'
    
    part :content_type => "text/html", :body => render_message("multipart_html", {})
    part "text/plain" do |p|
      p.body = render_message("multipart_plain", {})
    end
  end
  
  def implicit_multipart
    recipients 'some_address@email.com'
    subject    'multi part email'
    from       "another_user@email.com"
  end
end