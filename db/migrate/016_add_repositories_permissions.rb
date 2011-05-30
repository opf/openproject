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

class AddRepositoriesPermissions < ActiveRecord::Migration
  # model removed
  class Permission < ActiveRecord::Base; end

  def self.up
    Permission.create :controller => "repositories", :action => "show", :description => "button_view", :sort => 1450, :is_public => true
    Permission.create :controller => "repositories", :action => "browse", :description => "label_browse", :sort => 1460, :is_public => true
    Permission.create :controller => "repositories", :action => "entry", :description => "entry", :sort => 1462, :is_public => true
    Permission.create :controller => "repositories", :action => "revisions", :description => "label_view_revisions", :sort => 1470, :is_public => true
    Permission.create :controller => "repositories", :action => "revision", :description => "label_view_revisions", :sort => 1472, :is_public => true
    Permission.create :controller => "repositories", :action => "diff", :description => "diff", :sort => 1480, :is_public => true
  end

  def self.down
    Permission.find(:first, :conditions => ["controller=? and action=?", 'repositories', 'show']).destroy
    Permission.find(:first, :conditions => ["controller=? and action=?", 'repositories', 'browse']).destroy
    Permission.find(:first, :conditions => ["controller=? and action=?", 'repositories', 'entry']).destroy
    Permission.find(:first, :conditions => ["controller=? and action=?", 'repositories', 'revisions']).destroy
    Permission.find(:first, :conditions => ["controller=? and action=?", 'repositories', 'revision']).destroy
    Permission.find(:first, :conditions => ["controller=? and action=?", 'repositories', 'diff']).destroy
  end
end
