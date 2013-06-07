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

class FixUsersCustomValues < ActiveRecord::Migration
  def self.up
    CustomValue.update_all("customized_type = 'Principal'", "customized_type = 'User'")
  end

  def self.down
    CustomValue.update_all("customized_type = 'User'", "customized_type = 'Principal'")
  end
end
