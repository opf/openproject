
def last_email
  ActionMailer::Base.deliveries.last
end

def assigned_password_from_last_email
  last_email.text_part.body.to_s.match(/Password: (.+)$/)[1]
end

Then /^an e-mail should be sent containing "([^\"]*)"$/ do |content|
  # An e-mail should always have a text representation, so check
  # whether it contains the expected content
  last_email.text_part.body.should include(content)
end
