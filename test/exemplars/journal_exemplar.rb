#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Journal < ActiveRecord::Base
  generator_for :journaled, :method => :generate_issue
  generator_for :user, :method => :generate_user

  def self.generate_issue
    project = Project.generate!
    Issue.generate_for_project!(project)
  end

  def self.generate_user
    User.generate_with_protected!
  end
end
