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

class ChangeWikiContentsTextLimit < ActiveRecord::Migration
  def self.up
    # Migrates MySQL databases only
    # Postgres would raise an error (see http://dev.rubyonrails.org/ticket/3818)
    # Not fixed in Rails 2.3.5
    if ChiliProject::Database.mysql?
      max_size = 16.megabytes
      change_column :wiki_contents, :text, :text, :limit => max_size
      change_column :wiki_content_versions, :data, :binary, :limit => max_size
    end
  end

  def self.down
    # no-op
  end
end
