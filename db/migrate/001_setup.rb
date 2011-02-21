# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class Setup < ActiveRecord::Migration
  
  class User < ActiveRecord::Base; end
  # model removed
  class Permission < ActiveRecord::Base; end
  
  def self.up
    create_table "attachments", :force => true do |t|
      t.column "container_id", :integer, :default => 0, :null => false
      t.column "container_type", :string, :limit => 30, :default => "", :null => false
      t.column "filename", :string, :default => "", :null => false
      t.column "disk_filename", :string, :default => "", :null => false
      t.column "filesize", :integer, :default => 0, :null => false
      t.column "content_type", :string, :limit => 60, :default => ""
      t.column "digest", :string, :limit => 40, :default => "", :null => false
      t.column "downloads", :integer, :default => 0, :null => false
      t.column "author_id", :integer, :default => 0, :null => false
      t.column "created_on", :timestamp
    end

    create_table "auth_sources", :force => true do |t|
      t.column "type", :string, :limit => 30, :default => "", :null => false
      t.column "name", :string, :limit => 60, :default => "", :null => false
      t.column "host", :string, :limit => 60
      t.column "port", :integer
      t.column "account", :string, :limit => 60
      t.column "account_password", :string, :limit => 60
      t.column "base_dn", :string, :limit => 255
      t.column "attr_login", :string, :limit => 30
      t.column "attr_firstname", :string, :limit => 30
      t.column "attr_lastname", :string, :limit => 30
      t.column "attr_mail", :string, :limit => 30
      t.column "onthefly_register", :boolean, :default => false, :null => false
    end
    
    create_table "custom_fields", :force => true do |t|
      t.column "type", :string, :limit => 30, :default => "", :null => false
      t.column "name", :string, :limit => 30, :default => "", :null => false
      t.column "field_format", :string, :limit => 30, :default => "", :null => false
      t.column "possible_values", :text
      t.column "regexp", :string, :default => ""
      t.column "min_length", :integer, :default => 0, :null => false
      t.column "max_length", :integer, :default => 0, :null => false
      t.column "is_required", :boolean, :default => false, :null => false
      t.column "is_for_all", :boolean, :default => false, :null => false
    end
  
    create_table "custom_fields_projects", :id => false, :force => true do |t|
      t.column "custom_field_id", :integer, :default => 0, :null => false
      t.column "project_id", :integer, :default => 0, :null => false
    end

    create_table "custom_fields_trackers", :id => false, :force => true do |t|
      t.column "custom_field_id", :integer, :default => 0, :null => false
      t.column "tracker_id", :integer, :default => 0, :null => false
    end

    create_table "custom_values", :force => true do |t|
      t.column "customized_type", :string, :limit => 30, :default => "", :null => false
      t.column "customized_id", :integer, :default => 0, :null => false
      t.column "custom_field_id", :integer, :default => 0, :null => false
      t.column "value", :text
    end
  
    create_table "documents", :force => true do |t|
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "category_id", :integer, :default => 0, :null => false
      t.column "title", :string, :limit => 60, :default => "", :null => false
      t.column "description", :text
      t.column "created_on", :timestamp
    end
    
    add_index "documents", ["project_id"], :name => "documents_project_id"
  
    create_table "enumerations", :force => true do |t|
      t.column "opt", :string, :limit => 4, :default => "", :null => false
      t.column "name", :string, :limit => 30, :default => "", :null => false
    end
  
    create_table "issue_categories", :force => true do |t|
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "name", :string, :limit => 30, :default => "", :null => false
    end
    
    add_index "issue_categories", ["project_id"], :name => "issue_categories_project_id"
  
    create_table "issue_histories", :force => true do |t|
      t.column "issue_id", :integer, :default => 0, :null => false
      t.column "status_id", :integer, :default => 0, :null => false
      t.column "author_id", :integer, :default => 0, :null => false
      t.column "notes", :text
      t.column "created_on", :timestamp
    end
  
    add_index "issue_histories", ["issue_id"], :name => "issue_histories_issue_id"

    create_table "issue_statuses", :force => true do |t|
      t.column "name", :string, :limit => 30, :default => "", :null => false
      t.column "is_closed", :boolean, :default => false, :null => false
      t.column "is_default", :boolean, :default => false, :null => false
      t.column "html_color", :string, :limit => 6, :default => "FFFFFF", :null => false
    end
  
    create_table "issues", :force => true do |t|
      t.column "tracker_id", :integer, :default => 0, :null => false
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "subject", :string, :default => "", :null => false
      t.column "description", :text
      t.column "due_date", :date
      t.column "category_id", :integer
      t.column "status_id", :integer, :default => 0, :null => false
      t.column "assigned_to_id", :integer
      t.column "priority_id", :integer, :default => 0, :null => false
      t.column "fixed_version_id", :integer
      t.column "author_id", :integer, :default => 0, :null => false
      t.column "lock_version", :integer, :default => 0, :null => false
      t.column "created_on", :timestamp
      t.column "updated_on", :timestamp
    end
  
    add_index "issues", ["project_id"], :name => "issues_project_id"
  
    create_table "members", :force => true do |t|
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "role_id", :integer, :default => 0, :null => false
      t.column "created_on", :timestamp
    end
  
    create_table "news", :force => true do |t|
      t.column "project_id", :integer
      t.column "title", :string, :limit => 60, :default => "", :null => false
      t.column "summary", :string, :limit => 255, :default => ""
      t.column "description", :text
      t.column "author_id", :integer, :default => 0, :null => false
      t.column "created_on", :timestamp
    end
    
    add_index "news", ["project_id"], :name => "news_project_id"
  
    create_table "permissions", :force => true do |t|
      t.column "controller", :string, :limit => 30, :default => "", :null => false
      t.column "action", :string, :limit => 30, :default => "", :null => false
      t.column "description", :string, :limit => 60, :default => "", :null => false
      t.column "is_public", :boolean, :default => false, :null => false
      t.column "sort", :integer, :default => 0, :null => false
      t.column "mail_option", :boolean, :default => false, :null => false
      t.column "mail_enabled", :boolean, :default => false, :null => false
    end
  
    create_table "permissions_roles", :id => false, :force => true do |t|
      t.column "permission_id", :integer, :default => 0, :null => false
      t.column "role_id", :integer, :default => 0, :null => false
    end
  
    add_index "permissions_roles", ["role_id"], :name => "permissions_roles_role_id"
  
    create_table "projects", :force => true do |t|
      t.column "name", :string, :limit => 30, :default => "", :null => false
      t.column "description", :string, :default => "", :null => false
      t.column "homepage", :string, :limit => 60, :default => ""
      t.column "is_public", :boolean, :default => true, :null => false
      t.column "parent_id", :integer
      t.column "projects_count", :integer, :default => 0
      t.column "created_on", :timestamp
      t.column "updated_on", :timestamp
    end
  
    create_table "roles", :force => true do |t|
      t.column "name", :string, :limit => 30, :default => "", :null => false
    end

    create_table "tokens", :force => true do |t|
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "action", :string, :limit => 30, :default => "", :null => false
      t.column "value", :string, :limit => 40, :default => "", :null => false
      t.column "created_on", :datetime, :null => false
    end
  
    create_table "trackers", :force => true do |t|
      t.column "name", :string, :limit => 30, :default => "", :null => false
      t.column "is_in_chlog", :boolean, :default => false, :null => false
    end
  
    create_table "users", :force => true do |t|
      t.column "login", :string, :limit => 30, :default => "", :null => false
      t.column "hashed_password", :string, :limit => 40, :default => "", :null => false
      t.column "firstname", :string, :limit => 30, :default => "", :null => false
      t.column "lastname", :string, :limit => 30, :default => "", :null => false
      t.column "mail", :string, :limit => 60, :default => "", :null => false
      t.column "mail_notification", :boolean, :default => true, :null => false
      t.column "admin", :boolean, :default => false, :null => false
      t.column "status", :integer, :default => 1, :null => false
      t.column "last_login_on", :datetime
      t.column "language", :string, :limit => 2, :default => ""
      t.column "auth_source_id", :integer
      t.column "created_on", :timestamp
      t.column "updated_on", :timestamp
    end
  
    create_table "versions", :force => true do |t|
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "name", :string, :limit => 30, :default => "", :null => false
      t.column "description", :string, :default => ""
      t.column "effective_date", :date
      t.column "created_on", :timestamp
      t.column "updated_on", :timestamp
    end
    
    add_index "versions", ["project_id"], :name => "versions_project_id"
  
    create_table "workflows", :force => true do |t|
      t.column "tracker_id", :integer, :default => 0, :null => false
      t.column "old_status_id", :integer, :default => 0, :null => false
      t.column "new_status_id", :integer, :default => 0, :null => false
      t.column "role_id", :integer, :default => 0, :null => false
    end
  
    # project
    Permission.create :controller => "projects", :action => "show", :description => "label_overview", :sort => 100, :is_public => true
    Permission.create :controller => "projects", :action => "changelog", :description => "label_change_log", :sort => 105, :is_public => true
    Permission.create :controller => "reports", :action => "issue_report", :description => "label_report_plural", :sort => 110, :is_public => true
    Permission.create :controller => "projects", :action => "settings", :description => "label_settings", :sort => 150
    Permission.create :controller => "projects", :action => "edit", :description => "button_edit", :sort => 151
    # members
    Permission.create :controller => "projects", :action => "list_members", :description => "button_list", :sort => 200, :is_public => true
    Permission.create :controller => "projects", :action => "add_member", :description => "button_add", :sort => 220
    Permission.create :controller => "members", :action => "edit", :description => "button_edit", :sort => 221
    Permission.create :controller => "members", :action => "destroy", :description => "button_delete", :sort => 222
    # versions
    Permission.create :controller => "projects", :action => "add_version", :description => "button_add", :sort => 320
    Permission.create :controller => "versions", :action => "edit", :description => "button_edit", :sort => 321
    Permission.create :controller => "versions", :action => "destroy", :description => "button_delete", :sort => 322
    # issue categories
    Permission.create :controller => "projects", :action => "add_issue_category", :description => "button_add", :sort => 420
    Permission.create :controller => "issue_categories", :action => "edit", :description => "button_edit", :sort => 421
    Permission.create :controller => "issue_categories", :action => "destroy", :description => "button_delete", :sort => 422
    # issues
    Permission.create :controller => "projects", :action => "list_issues", :description => "button_list", :sort => 1000, :is_public => true
    Permission.create :controller => "projects", :action => "export_issues_csv", :description => "label_export_csv", :sort => 1001, :is_public => true
    Permission.create :controller => "issues", :action => "show", :description => "button_view", :sort => 1005, :is_public => true
    Permission.create :controller => "issues", :action => "download", :description => "button_download", :sort => 1010, :is_public => true
    Permission.create :controller => "projects", :action => "add_issue", :description => "button_add", :sort => 1050, :mail_option => 1, :mail_enabled => 1
    Permission.create :controller => "issues", :action => "edit", :description => "button_edit", :sort => 1055
    Permission.create :controller => "issues", :action => "change_status", :description => "label_change_status", :sort => 1060, :mail_option => 1, :mail_enabled => 1
    Permission.create :controller => "issues", :action => "destroy", :description => "button_delete", :sort => 1065
    Permission.create :controller => "issues", :action => "add_attachment", :description => "label_attachment_new", :sort => 1070
    Permission.create :controller => "issues", :action => "destroy_attachment", :description => "label_attachment_delete", :sort => 1075
    # news
    Permission.create :controller => "projects", :action => "list_news", :description => "button_list", :sort => 1100, :is_public => true
    Permission.create :controller => "news", :action => "show", :description => "button_view", :sort => 1101, :is_public => true
    Permission.create :controller => "projects", :action => "add_news", :description => "button_add", :sort => 1120
    Permission.create :controller => "news", :action => "edit", :description => "button_edit", :sort => 1121
    Permission.create :controller => "news", :action => "destroy", :description => "button_delete", :sort => 1122
    # documents
    Permission.create :controller => "projects", :action => "list_documents", :description => "button_list", :sort => 1200, :is_public => true
    Permission.create :controller => "documents", :action => "show", :description => "button_view", :sort => 1201, :is_public => true
    Permission.create :controller => "documents", :action => "download", :description => "button_download", :sort => 1202, :is_public => true
    Permission.create :controller => "projects", :action => "add_document", :description => "button_add", :sort => 1220
    Permission.create :controller => "documents", :action => "edit", :description => "button_edit", :sort => 1221
    Permission.create :controller => "documents", :action => "destroy", :description => "button_delete", :sort => 1222
    Permission.create :controller => "documents", :action => "add_attachment", :description => "label_attachment_new", :sort => 1223
    Permission.create :controller => "documents", :action => "destroy_attachment", :description => "label_attachment_delete", :sort => 1224
    # files
    Permission.create :controller => "projects", :action => "list_files", :description => "button_list", :sort => 1300, :is_public => true
    Permission.create :controller => "versions", :action => "download", :description => "button_download", :sort => 1301, :is_public => true
    Permission.create :controller => "projects", :action => "add_file", :description => "button_add", :sort => 1320
    Permission.create :controller => "versions", :action => "destroy_file", :description => "button_delete", :sort => 1322
    
    # create default administrator account
    user = User.create :login => "admin",
                       :hashed_password => "d033e22ae348aeb5660fc2140aec35850c4da997",
                       :admin => true,
                       :firstname => "ChiliProject",
                       :lastname => "Admin",
                       :mail => "admin@example.net",
                       :mail_notification => true,
                       :language => "en",
                       :status => 1
  end

  def self.down
    drop_table :attachments
    drop_table :auth_sources
    drop_table :custom_fields
    drop_table :custom_fields_projects
    drop_table :custom_fields_trackers
    drop_table :custom_values
    drop_table :documents
    drop_table :enumerations
    drop_table :issue_categories
    drop_table :issue_histories
    drop_table :issue_statuses
    drop_table :issues
    drop_table :members
    drop_table :news
    drop_table :permissions
    drop_table :permissions_roles
    drop_table :projects
    drop_table :roles
    drop_table :trackers
    drop_table :tokens
    drop_table :users
    drop_table :versions
    drop_table :workflows
  end
end
