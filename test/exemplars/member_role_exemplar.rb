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

class MemberRole < ActiveRecord::Base
  generator_for :member, :method => :generate_member
  generator_for :role, :method => :generate_role

  def self.generate_role
    Role.generate!
  end

  def self.generate_member
    Member.generate!
  end
end
