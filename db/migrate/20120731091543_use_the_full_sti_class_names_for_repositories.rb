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

class UseTheFullStiClassNamesForRepositories < ActiveRecord::Migration
  def self.up
    concatenation = "('Repository::' || type)"

    # special concat for mysql
    if ChiliProject::Database.mysql?
      concatenation = "CONCAT('Repository::', type)"
    end

    Repository.update_all "type = #{concatenation}", "type NOT LIKE 'Repository::%'"
  end

  def self.down
    # noop, full class name should also work with older versions of active record
  end
end
