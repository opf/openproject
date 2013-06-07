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

class AddViewIssuesPermission < ActiveRecord::Migration
  def self.up
    Role.find(:all).each do |r|
      r.add_permission!(:view_issues)
    end
  end

  def self.down
    Role.find(:all).each do |r|
      r.remove_permission!(:view_issues)
    end
  end
end
