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

class RemoveDoubleInitialWikiContentJournals < ActiveRecord::Migration
  def self.up
    # Remove the newest initial WikiContentJournal (the one erroneously created by a former migration) if there are more than one
    WikiContentJournal.find(:all, :conditions => {:version => 1}).group_by(&:journaled_id).select {|k,v| v.size > 1}.each {|k,v| v.max_by(&:created_at).delete}
  end

  def self.down
    # noop
  end
end
