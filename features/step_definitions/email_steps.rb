
def last_email
  ActionMailer::Base.deliveries.last
end

def assigned_password_from_last_email
  last_email.text_part.body.to_s.match(/Password: (.+)$/)[1]
end

Then /^an e-mail should be sent containing "([^\"]*)"$/ do |content|
  last_email.text_part.body.should include(content)
  last_email.html_part.body.should include(content)
end
