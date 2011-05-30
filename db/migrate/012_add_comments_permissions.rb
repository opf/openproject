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

class AddCommentsPermissions < ActiveRecord::Migration
  # model removed
  class Permission < ActiveRecord::Base; end

  def self.up
    Permission.create :controller => "news", :action => "add_comment", :description => "label_comment_add", :sort => 1130, :is_public => false, :mail_option => 0, :mail_enabled => 0
    Permission.create :controller => "news", :action => "destroy_comment", :description => "label_comment_delete", :sort => 1133, :is_public => false, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find(:first, :conditions => ["controller=? and action=?", 'news', 'add_comment']).destroy
    Permission.find(:first, :conditions => ["controller=? and action=?", 'news', 'destroy_comment']).destroy
  end
end
