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
