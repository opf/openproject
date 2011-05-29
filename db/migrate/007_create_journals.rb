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

class CreateJournals < ActiveRecord::Migration

  # model removed, but needed for data migration
  class IssueHistory < ActiveRecord::Base; belongs_to :issue; end
  # model removed
  class Permission < ActiveRecord::Base; end
  
  def self.up
    create_table :journals, :force => true do |t|
      t.column "journalized_id", :integer, :default => 0, :null => false
      t.column "journalized_type", :string, :limit => 30, :default => "", :null => false
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "notes", :text
      t.column "created_on", :datetime, :null => false
    end
    create_table :journal_details, :force => true do |t|
      t.column "journal_id", :integer, :default => 0, :null => false
      t.column "property", :string, :limit => 30, :default => "", :null => false
      t.column "prop_key", :string, :limit => 30, :default => "", :null => false
      t.column "old_value", :string
      t.column "value", :string
    end
    
    # indexes
    add_index "journals", ["journalized_id", "journalized_type"], :name => "journals_journalized_id"
    add_index "journal_details", ["journal_id"], :name => "journal_details_journal_id"
    
    Permission.create :controller => "issues", :action => "history", :description => "label_history", :sort => 1006, :is_public => true, :mail_option => 0, :mail_enabled => 0

    # data migration
    IssueHistory.find(:all, :include => :issue).each {|h|
      j = Journal.new(:journalized => h.issue, :user_id => h.author_id, :notes => h.notes, :created_on => h.created_on)
      j.details << JournalDetail.new(:property => 'attr', :prop_key => 'status_id', :value => h.status_id)
      j.save    
    }    

    drop_table :issue_histories
  end

  def self.down
    drop_table :journal_details
    drop_table :journals
    
    create_table "issue_histories", :force => true do |t|
      t.column "issue_id", :integer, :default => 0, :null => false
      t.column "status_id", :integer, :default => 0, :null => false
      t.column "author_id", :integer, :default => 0, :null => false
      t.column "notes", :text, :default => ""
      t.column "created_on", :timestamp
    end
  
    add_index "issue_histories", ["issue_id"], :name => "issue_histories_issue_id"

    Permission.find(:first, :conditions => ["controller=? and action=?", 'issues', 'history']).destroy
  end
end
