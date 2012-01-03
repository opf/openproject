#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class AddWikiAttachmentsPermissions < ActiveRecord::Migration
  # model removed
  class Permission < ActiveRecord::Base; end

  def self.up
    Permission.create :controller => 'wiki', :action => 'add_attachment', :description => 'label_attachment_new', :sort => 1750, :is_public => false, :mail_option => 0, :mail_enabled => 0
    Permission.create :controller => 'wiki', :action => 'destroy_attachment', :description => 'label_attachment_delete', :sort => 1755, :is_public => false, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find_by_controller_and_action('wiki', 'add_attachment').destroy
    Permission.find_by_controller_and_action('wiki', 'destroy_attachment').destroy
  end
end
