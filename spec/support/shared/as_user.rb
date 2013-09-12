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

# Method for controller tests where you want to do everything in the context of the
# provided user without the hassle of locking in the user and cleaning up User.current
# afterwards
#
# Example usage:
#
#   as_logged_in_user admin do
#     post :create, { :name => "foo" }
#   end

def as_logged_in_user(user, &block)
  @controller.stub(:user_setup).and_return(user)
  User.stub(:current).and_return(user)

  yield
end
