#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++


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
