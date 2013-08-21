#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2011-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Then(/^the user "(.*?)" should( not)? be available as a participant$/) do |login, negative|
  user = User.find_by_login(login)

  step(%{I should#{negative} see "#{user.name}" within "#meeting-form table.list"})
end

