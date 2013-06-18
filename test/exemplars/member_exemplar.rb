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

class Member < ActiveRecord::Base
  generator_for :roles, :method => :generate_roles
  generator_for :principal, :method => :generate_user

  def self.generate_roles
    [Role.generate!]
  end

  def self.generate_user
    User.generate_with_protected!
  end
end
