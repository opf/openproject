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

class AddRelationsPermissions < ActiveRecord::Migration
  # model removed
  class Permission < ActiveRecord::Base; end

  def self.up
    Permission.create :controller => "issue_relations", :action => "new", :description => "label_relation_new", :sort => 1080, :is_public => false, :mail_option => 0, :mail_enabled => 0
    Permission.create :controller => "issue_relations", :action => "destroy", :description => "label_relation_delete", :sort => 1085, :is_public => false, :mail_option => 0, :mail_enabled => 0
  end

  def self.down
    Permission.find_by_controller_and_action("issue_relations", "new").destroy
    Permission.find_by_controller_and_action("issue_relations", "destroy").destroy
  end
end
