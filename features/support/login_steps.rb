#-- encoding: UTF-8
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


module LoginSteps
  def login(login, password)
    # visit '/logout' # uncomment me if needed
    visit '/login'
    fill_in User.human_attribute_name(:login)+":", :with => login
    fill_in 'Password:', :with => password
    click_button 'Login »'
  end
end

World(LoginSteps)
