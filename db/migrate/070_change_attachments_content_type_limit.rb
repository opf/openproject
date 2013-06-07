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

class ChangeAttachmentsContentTypeLimit < ActiveRecord::Migration
  def self.up
    change_column :attachments, :content_type, :string, :limit => nil
  end

  def self.down
    change_column :attachments, :content_type, :string, :limit => 60
  end
end
