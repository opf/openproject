# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150623151337) do

  create_table "attachable_journals", :force => true do |t|
    t.integer "journal_id",                    :null => false
    t.integer "attachment_id",                 :null => false
    t.string  "filename",      :default => "", :null => false
  end

  add_index "attachable_journals", ["attachment_id"], :name => "index_attachable_journals_on_attachment_id"
  add_index "attachable_journals", ["journal_id"], :name => "index_attachable_journals_on_journal_id"

  create_table "attachment_journals", :force => true do |t|
    t.integer "journal_id",                                   :null => false
    t.integer "container_id",                 :default => 0,  :null => false
    t.string  "container_type", :limit => 30, :default => "", :null => false
    t.string  "filename",                     :default => "", :null => false
    t.string  "disk_filename",                :default => "", :null => false
    t.integer "filesize",                     :default => 0,  :null => false
    t.string  "content_type",                 :default => ""
    t.string  "digest",         :limit => 40, :default => "", :null => false
    t.integer "downloads",                    :default => 0,  :null => false
    t.integer "author_id",                    :default => 0,  :null => false
    t.text    "description"
  end

  add_index "attachment_journals", ["journal_id"], :name => "index_attachment_journals_on_journal_id"

  create_table "attachments", :force => true do |t|
    t.integer  "container_id",                 :default => 0,  :null => false
    t.string   "container_type", :limit => 30, :default => "", :null => false
    t.string   "filename",                     :default => "", :null => false
    t.string   "disk_filename",                :default => "", :null => false
    t.integer  "filesize",                     :default => 0,  :null => false
    t.string   "content_type",                 :default => ""
    t.string   "digest",         :limit => 40, :default => "", :null => false
    t.integer  "downloads",                    :default => 0,  :null => false
    t.integer  "author_id",                    :default => 0,  :null => false
    t.datetime "created_on"
    t.string   "description"
    t.string   "file"
  end

  add_index "attachments", ["author_id"], :name => "index_attachments_on_author_id"
  add_index "attachments", ["container_id", "container_type"], :name => "index_attachments_on_container_id_and_container_type"
  add_index "attachments", ["created_on"], :name => "index_attachments_on_created_on"

  create_table "auth_sources", :force => true do |t|
    t.string  "type",              :limit => 30, :default => "",    :null => false
    t.string  "name",              :limit => 60, :default => "",    :null => false
    t.string  "host",              :limit => 60
    t.integer "port"
    t.string  "account"
    t.string  "account_password",                :default => ""
    t.string  "base_dn"
    t.string  "attr_login",        :limit => 30
    t.string  "attr_firstname",    :limit => 30
    t.string  "attr_lastname",     :limit => 30
    t.string  "attr_mail",         :limit => 30
    t.boolean "onthefly_register",               :default => false, :null => false
    t.boolean "tls",                             :default => false, :null => false
  end

  add_index "auth_sources", ["id", "type"], :name => "index_auth_sources_on_id_and_type"

  create_table "available_project_statuses", :force => true do |t|
    t.integer  "project_type_id"
    t.integer  "reported_project_status_id"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "available_project_statuses", ["project_type_id"], :name => "index_timelines_available_project_statuses_on_project_type_id"
  add_index "available_project_statuses", ["reported_project_status_id"], :name => "index_avail_project_statuses_on_rep_project_status_id"

  create_table "boards", :force => true do |t|
    t.integer "project_id",                      :null => false
    t.string  "name",            :default => "", :null => false
    t.string  "description"
    t.integer "position",        :default => 1
    t.integer "topics_count",    :default => 0,  :null => false
    t.integer "messages_count",  :default => 0,  :null => false
    t.integer "last_message_id"
  end

  add_index "boards", ["last_message_id"], :name => "index_boards_on_last_message_id"
  add_index "boards", ["project_id"], :name => "boards_project_id"

  create_table "categories", :force => true do |t|
    t.integer "project_id",                   :default => 0,  :null => false
    t.string  "name",           :limit => 30, :default => "", :null => false
    t.integer "assigned_to_id"
  end

  add_index "categories", ["assigned_to_id"], :name => "index_issue_categories_on_assigned_to_id"
  add_index "categories", ["project_id"], :name => "issue_categories_project_id"

  create_table "changes", :force => true do |t|
    t.integer "changeset_id",                               :null => false
    t.string  "action",        :limit => 1, :default => "", :null => false
    t.text    "path",                                       :null => false
    t.text    "from_path"
    t.string  "from_revision"
    t.string  "revision"
    t.string  "branch"
  end

  add_index "changes", ["changeset_id"], :name => "changesets_changeset_id"

  create_table "changeset_journals", :force => true do |t|
    t.integer  "journal_id",    :null => false
    t.integer  "repository_id", :null => false
    t.string   "revision",      :null => false
    t.string   "committer"
    t.datetime "committed_on",  :null => false
    t.text     "comments"
    t.date     "commit_date"
    t.string   "scmid"
    t.integer  "user_id"
  end

  add_index "changeset_journals", ["journal_id"], :name => "index_changeset_journals_on_journal_id"

  create_table "changesets", :force => true do |t|
    t.integer  "repository_id", :null => false
    t.string   "revision",      :null => false
    t.string   "committer"
    t.datetime "committed_on",  :null => false
    t.text     "comments"
    t.date     "commit_date"
    t.string   "scmid"
    t.integer  "user_id"
  end

  add_index "changesets", ["committed_on"], :name => "index_changesets_on_committed_on"
  add_index "changesets", ["repository_id", "revision"], :name => "changesets_repos_rev", :unique => true
  add_index "changesets", ["repository_id", "scmid"], :name => "changesets_repos_scmid"
  add_index "changesets", ["repository_id"], :name => "index_changesets_on_repository_id"
  add_index "changesets", ["user_id"], :name => "index_changesets_on_user_id"

  create_table "changesets_work_packages", :id => false, :force => true do |t|
    t.integer "changeset_id",    :null => false
    t.integer "work_package_id", :null => false
  end

  add_index "changesets_work_packages", ["changeset_id", "work_package_id"], :name => "changesets_work_packages_ids", :unique => true

  create_table "comments", :force => true do |t|
    t.string   "commented_type", :limit => 30, :default => "", :null => false
    t.integer  "commented_id",                 :default => 0,  :null => false
    t.integer  "author_id",                    :default => 0,  :null => false
    t.text     "comments"
    t.datetime "created_on",                                   :null => false
    t.datetime "updated_on",                                   :null => false
  end

  add_index "comments", ["author_id"], :name => "index_comments_on_author_id"
  add_index "comments", ["commented_id", "commented_type"], :name => "index_comments_on_commented_id_and_commented_type"

  create_table "custom_field_translations", :force => true do |t|
    t.integer  "custom_field_id", :null => false
    t.string   "locale",          :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.string   "name"
    t.text     "default_value"
    t.text     "possible_values"
  end

  add_index "custom_field_translations", ["custom_field_id"], :name => "index_custom_field_translations_on_custom_field_id"
  add_index "custom_field_translations", ["locale"], :name => "index_custom_field_translations_on_locale"

  create_table "custom_fields", :force => true do |t|
    t.string  "type",         :limit => 30, :default => "",    :null => false
    t.string  "field_format", :limit => 30, :default => "",    :null => false
    t.string  "regexp",                     :default => ""
    t.integer "min_length",                 :default => 0,     :null => false
    t.integer "max_length",                 :default => 0,     :null => false
    t.boolean "is_required",                :default => false, :null => false
    t.boolean "is_for_all",                 :default => false, :null => false
    t.boolean "is_filter",                  :default => false, :null => false
    t.integer "position",                   :default => 1
    t.boolean "searchable",                 :default => false
    t.boolean "editable",                   :default => true
    t.boolean "visible",                    :default => true,  :null => false
  end

  add_index "custom_fields", ["id", "type"], :name => "index_custom_fields_on_id_and_type"

  create_table "custom_fields_projects", :id => false, :force => true do |t|
    t.integer "custom_field_id", :default => 0, :null => false
    t.integer "project_id",      :default => 0, :null => false
  end

  add_index "custom_fields_projects", ["custom_field_id", "project_id"], :name => "index_custom_fields_projects_on_custom_field_id_and_project_id"

  create_table "custom_fields_types", :id => false, :force => true do |t|
    t.integer "custom_field_id", :default => 0, :null => false
    t.integer "type_id",         :default => 0, :null => false
  end

  add_index "custom_fields_types", ["custom_field_id", "type_id"], :name => "custom_fields_types_unique", :unique => true

  create_table "custom_values", :force => true do |t|
    t.string  "customized_type", :limit => 30, :default => "", :null => false
    t.integer "customized_id",                 :default => 0,  :null => false
    t.integer "custom_field_id",               :default => 0,  :null => false
    t.text    "value"
  end

  add_index "custom_values", ["custom_field_id"], :name => "index_custom_values_on_custom_field_id"
  add_index "custom_values", ["customized_type", "customized_id"], :name => "custom_values_customized"

  create_table "customizable_journals", :force => true do |t|
    t.integer "journal_id",      :null => false
    t.integer "custom_field_id", :null => false
    t.text    "value"
  end

  add_index "customizable_journals", ["custom_field_id"], :name => "index_customizable_journals_on_custom_field_id"
  add_index "customizable_journals", ["journal_id"], :name => "index_customizable_journals_on_journal_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.string   "queue"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "enabled_modules", :force => true do |t|
    t.integer "project_id"
    t.string  "name",       :null => false
  end

  add_index "enabled_modules", ["name"], :name => "index_enabled_modules_on_name"
  add_index "enabled_modules", ["project_id"], :name => "enabled_modules_project_id"

  create_table "enumerations", :force => true do |t|
    t.string  "name",       :limit => 30, :default => "",    :null => false
    t.integer "position",                 :default => 1
    t.boolean "is_default",               :default => false, :null => false
    t.string  "type"
    t.boolean "active",                   :default => true,  :null => false
    t.integer "project_id"
    t.integer "parent_id"
  end

  add_index "enumerations", ["id", "type"], :name => "index_enumerations_on_id_and_type"
  add_index "enumerations", ["project_id"], :name => "index_enumerations_on_project_id"

  create_table "group_users", :id => false, :force => true do |t|
    t.integer "group_id", :null => false
    t.integer "user_id",  :null => false
  end

  add_index "group_users", ["group_id", "user_id"], :name => "group_user_ids", :unique => true

  create_table "journals", :force => true do |t|
    t.integer  "journable_id"
    t.string   "journable_type"
    t.integer  "user_id",        :default => 0, :null => false
    t.text     "notes"
    t.datetime "created_at",                    :null => false
    t.integer  "version",        :default => 0, :null => false
    t.string   "activity_type"
  end

  add_index "journals", ["activity_type"], :name => "index_journals_on_activity_type"
  add_index "journals", ["created_at"], :name => "index_journals_on_created_at"
  add_index "journals", ["journable_id"], :name => "index_journals_on_journable_id"
  add_index "journals", ["journable_type"], :name => "index_journals_on_journable_type"
  add_index "journals", ["user_id"], :name => "index_journals_on_user_id"

  create_table "legacy_default_planning_element_types", :force => true do |t|
    t.integer  "project_type_id"
    t.integer  "planning_element_type_id"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "legacy_default_planning_element_types", ["planning_element_type_id"], :name => "index_default_pe_types_on_pe_type_id"
  add_index "legacy_default_planning_element_types", ["project_type_id"], :name => "index_default_pe_types_on_project_type_id"

  create_table "legacy_enabled_planning_element_types", :force => true do |t|
    t.integer  "project_id"
    t.integer  "planning_element_type_id"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "legacy_enabled_planning_element_types", ["planning_element_type_id"], :name => "index_enabled_pe_types_on_pe_type_id"
  add_index "legacy_enabled_planning_element_types", ["project_id"], :name => "index_timelines_enabled_planning_element_types_on_project_id"

  create_table "legacy_issues", :force => true do |t|
    t.integer  "tracker_id",       :default => 0,  :null => false
    t.integer  "project_id",       :default => 0,  :null => false
    t.string   "subject",          :default => "", :null => false
    t.text     "description"
    t.date     "due_date"
    t.integer  "category_id"
    t.integer  "status_id",        :default => 0,  :null => false
    t.integer  "assigned_to_id"
    t.integer  "priority_id",      :default => 0,  :null => false
    t.integer  "fixed_version_id"
    t.integer  "author_id",        :default => 0,  :null => false
    t.integer  "lock_version",     :default => 0,  :null => false
    t.datetime "created_on"
    t.datetime "updated_on"
    t.date     "start_date"
    t.integer  "done_ratio",       :default => 0,  :null => false
    t.float    "estimated_hours"
    t.integer  "parent_id"
    t.integer  "root_id"
    t.integer  "lft"
    t.integer  "rgt"
  end

  add_index "legacy_issues", ["assigned_to_id"], :name => "index_issues_on_assigned_to_id"
  add_index "legacy_issues", ["author_id"], :name => "index_issues_on_author_id"
  add_index "legacy_issues", ["category_id"], :name => "index_issues_on_category_id"
  add_index "legacy_issues", ["created_on"], :name => "index_issues_on_created_on"
  add_index "legacy_issues", ["fixed_version_id"], :name => "index_issues_on_fixed_version_id"
  add_index "legacy_issues", ["priority_id"], :name => "index_issues_on_priority_id"
  add_index "legacy_issues", ["project_id"], :name => "issues_project_id"
  add_index "legacy_issues", ["root_id", "lft", "rgt"], :name => "index_issues_on_root_id_and_lft_and_rgt"
  add_index "legacy_issues", ["status_id"], :name => "index_issues_on_status_id"
  add_index "legacy_issues", ["tracker_id"], :name => "index_issues_on_tracker_id"

  create_table "legacy_journals", :force => true do |t|
    t.integer  "journaled_id",  :default => 0, :null => false
    t.integer  "user_id",       :default => 0, :null => false
    t.text     "notes"
    t.datetime "created_at",                   :null => false
    t.integer  "version",       :default => 0, :null => false
    t.string   "activity_type"
    t.text     "changed_data"
    t.string   "type"
  end

  add_index "legacy_journals", ["activity_type"], :name => "idx_lgcy_journals_on_activity_type"
  add_index "legacy_journals", ["created_at"], :name => "idx_lgcy_journals_on_created_at"
  add_index "legacy_journals", ["journaled_id"], :name => "idx_lgcy_journals_on_journaled_id"
  add_index "legacy_journals", ["type"], :name => "idx_lgcy_journals_on_type"
  add_index "legacy_journals", ["user_id"], :name => "idx_lgcy_journals_on_user_id"

  create_table "legacy_planning_element_types", :force => true do |t|
    t.string   "name",                              :null => false
    t.boolean  "in_aggregation", :default => true,  :null => false
    t.boolean  "is_milestone",   :default => false, :null => false
    t.boolean  "is_default",     :default => false, :null => false
    t.integer  "position",       :default => 1
    t.integer  "color_id"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.integer  "new_id"
  end

  add_index "legacy_planning_element_types", ["color_id"], :name => "index_timelines_planning_element_types_on_color_id"

  create_table "legacy_planning_elements", :force => true do |t|
    t.string   "name",                            :null => false
    t.text     "description"
    t.text     "planning_element_status_comment"
    t.date     "start_date",                      :null => false
    t.date     "end_date",                        :null => false
    t.integer  "parent_id"
    t.integer  "project_id"
    t.integer  "responsible_id"
    t.integer  "planning_element_type_id"
    t.integer  "planning_element_status_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.datetime "deleted_at"
    t.integer  "new_id"
  end

  add_index "legacy_planning_elements", ["parent_id"], :name => "index_timelines_planning_elements_on_parent_id"
  add_index "legacy_planning_elements", ["planning_element_status_id"], :name => "index_timelines_planning_elements_on_planning_element_status_id"
  add_index "legacy_planning_elements", ["planning_element_type_id"], :name => "index_timelines_planning_elements_on_planning_element_type_id"
  add_index "legacy_planning_elements", ["project_id"], :name => "index_timelines_planning_elements_on_project_id"
  add_index "legacy_planning_elements", ["responsible_id"], :name => "index_timelines_planning_elements_on_responsible_id"

  create_table "legacy_user_identity_urls", :force => true do |t|
    t.string "login",        :limit => 256, :default => "", :null => false
    t.string "identity_url"
  end

  create_table "member_roles", :force => true do |t|
    t.integer "member_id",      :null => false
    t.integer "role_id",        :null => false
    t.integer "inherited_from"
  end

  add_index "member_roles", ["member_id"], :name => "index_member_roles_on_member_id"
  add_index "member_roles", ["role_id"], :name => "index_member_roles_on_role_id"

  create_table "members", :force => true do |t|
    t.integer  "user_id",           :default => 0,     :null => false
    t.integer  "project_id",        :default => 0,     :null => false
    t.datetime "created_on"
    t.boolean  "mail_notification", :default => false, :null => false
  end

  add_index "members", ["project_id"], :name => "index_members_on_project_id"
  add_index "members", ["user_id", "project_id"], :name => "index_members_on_user_id_and_project_id", :unique => true
  add_index "members", ["user_id"], :name => "index_members_on_user_id"

  create_table "menu_items", :force => true do |t|
    t.string  "name"
    t.string  "title"
    t.integer "parent_id"
    t.text    "options"
    t.integer "navigatable_id"
    t.string  "type"
  end

  add_index "menu_items", ["navigatable_id", "title"], :name => "index_menu_items_on_navigatable_id_and_title"
  add_index "menu_items", ["parent_id"], :name => "index_menu_items_on_parent_id"

  create_table "message_journals", :force => true do |t|
    t.integer "journal_id",                       :null => false
    t.integer "board_id",                         :null => false
    t.integer "parent_id"
    t.string  "subject",       :default => "",    :null => false
    t.text    "content"
    t.integer "author_id"
    t.integer "replies_count", :default => 0,     :null => false
    t.integer "last_reply_id"
    t.boolean "locked",        :default => false
    t.integer "sticky",        :default => 0
  end

  add_index "message_journals", ["journal_id"], :name => "index_message_journals_on_journal_id"

  create_table "messages", :force => true do |t|
    t.integer  "board_id",                         :null => false
    t.integer  "parent_id"
    t.string   "subject",       :default => "",    :null => false
    t.text     "content"
    t.integer  "author_id"
    t.integer  "replies_count", :default => 0,     :null => false
    t.integer  "last_reply_id"
    t.datetime "created_on",                       :null => false
    t.datetime "updated_on",                       :null => false
    t.boolean  "locked",        :default => false
    t.integer  "sticky",        :default => 0
    t.datetime "sticked_on"
  end

  add_index "messages", ["author_id"], :name => "index_messages_on_author_id"
  add_index "messages", ["board_id"], :name => "messages_board_id"
  add_index "messages", ["created_on"], :name => "index_messages_on_created_on"
  add_index "messages", ["last_reply_id"], :name => "index_messages_on_last_reply_id"
  add_index "messages", ["parent_id"], :name => "messages_parent_id"

  create_table "news", :force => true do |t|
    t.integer  "project_id"
    t.string   "title",          :limit => 60, :default => "", :null => false
    t.string   "summary",                      :default => ""
    t.text     "description"
    t.integer  "author_id",                    :default => 0,  :null => false
    t.datetime "created_on"
    t.integer  "comments_count",               :default => 0,  :null => false
  end

  add_index "news", ["author_id"], :name => "index_news_on_author_id"
  add_index "news", ["created_on"], :name => "index_news_on_created_on"
  add_index "news", ["project_id"], :name => "news_project_id"

  create_table "news_journals", :force => true do |t|
    t.integer "journal_id",                                   :null => false
    t.integer "project_id"
    t.string  "title",          :limit => 60, :default => "", :null => false
    t.string  "summary",                      :default => ""
    t.text    "description"
    t.integer "author_id",                    :default => 0,  :null => false
    t.integer "comments_count",               :default => 0,  :null => false
  end

  add_index "news_journals", ["journal_id"], :name => "index_news_journals_on_journal_id"

  create_table "planning_element_type_colors", :force => true do |t|
    t.string   "name",                      :null => false
    t.string   "hexcode",                   :null => false
    t.integer  "position",   :default => 1
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "project_associations", :force => true do |t|
    t.integer  "project_a_id"
    t.integer  "project_b_id"
    t.text     "description"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "project_associations", ["project_a_id"], :name => "index_timelines_project_associations_on_project_a_id"
  add_index "project_associations", ["project_b_id"], :name => "index_timelines_project_associations_on_project_b_id"

  create_table "project_types", :force => true do |t|
    t.string   "name",               :default => "",   :null => false
    t.boolean  "allows_association", :default => true, :null => false
    t.integer  "position",           :default => 1
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
  end

  create_table "projects", :force => true do |t|
    t.string   "name",                         :default => "",   :null => false
    t.text     "description"
    t.string   "homepage",                     :default => ""
    t.boolean  "is_public",                    :default => true, :null => false
    t.integer  "parent_id"
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "identifier"
    t.integer  "status",                       :default => 1,    :null => false
    t.integer  "lft"
    t.integer  "rgt"
    t.text     "summary"
    t.integer  "project_type_id"
    t.integer  "responsible_id"
    t.integer  "work_packages_responsible_id"
  end

  add_index "projects", ["identifier"], :name => "index_projects_on_identifier"
  add_index "projects", ["lft"], :name => "index_projects_on_lft"
  add_index "projects", ["project_type_id"], :name => "index_projects_on_timelines_project_type_id"
  add_index "projects", ["responsible_id"], :name => "index_projects_on_timelines_responsible_id"
  add_index "projects", ["rgt"], :name => "index_projects_on_rgt"
  add_index "projects", ["work_packages_responsible_id"], :name => "index_projects_on_work_packages_responsible_id"

  create_table "projects_types", :id => false, :force => true do |t|
    t.integer "project_id", :default => 0, :null => false
    t.integer "type_id",    :default => 0, :null => false
  end

  add_index "projects_types", ["project_id", "type_id"], :name => "projects_types_unique", :unique => true
  add_index "projects_types", ["project_id"], :name => "projects_types_project_id"

  create_table "queries", :force => true do |t|
    t.integer "project_id"
    t.string  "name",          :default => "",    :null => false
    t.text    "filters"
    t.integer "user_id",       :default => 0,     :null => false
    t.boolean "is_public",     :default => false, :null => false
    t.text    "column_names"
    t.text    "sort_criteria"
    t.string  "group_by"
    t.boolean "display_sums"
  end

  add_index "queries", ["project_id"], :name => "index_queries_on_project_id"
  add_index "queries", ["user_id"], :name => "index_queries_on_user_id"

  create_table "relations", :force => true do |t|
    t.integer "from_id",                       :null => false
    t.integer "to_id",                         :null => false
    t.string  "relation_type", :default => "", :null => false
    t.integer "delay"
  end

  add_index "relations", ["from_id"], :name => "index_issue_relations_on_issue_from_id"
  add_index "relations", ["to_id"], :name => "index_issue_relations_on_issue_to_id"

  create_table "reportings", :force => true do |t|
    t.text     "reported_project_status_comment"
    t.integer  "project_id"
    t.integer  "reporting_to_project_id"
    t.integer  "reported_project_status_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "reportings", ["project_id"], :name => "index_timelines_reportings_on_project_id"
  add_index "reportings", ["reported_project_status_id"], :name => "index_timelines_reportings_on_reported_project_status_id"
  add_index "reportings", ["reporting_to_project_id"], :name => "index_timelines_reportings_on_reporting_to_project_id"

  create_table "repositories", :force => true do |t|
    t.integer "project_id",                  :default => 0,  :null => false
    t.string  "url",                         :default => "", :null => false
    t.string  "login",         :limit => 60, :default => ""
    t.string  "password",                    :default => ""
    t.string  "root_url",                    :default => ""
    t.string  "type"
    t.string  "path_encoding", :limit => 64
    t.string  "log_encoding",  :limit => 64
  end

  add_index "repositories", ["project_id"], :name => "index_repositories_on_project_id"

  create_table "roles", :force => true do |t|
    t.string  "name",        :limit => 30, :default => "",   :null => false
    t.integer "position",                  :default => 1
    t.boolean "assignable",                :default => true
    t.integer "builtin",                   :default => 0,    :null => false
    t.text    "permissions"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.string   "name",       :default => "", :null => false
    t.text     "value"
    t.datetime "updated_on"
  end

  add_index "settings", ["name"], :name => "index_settings_on_name"

  create_table "statuses", :force => true do |t|
    t.string  "name",               :limit => 30, :default => "",    :null => false
    t.boolean "is_closed",                        :default => false, :null => false
    t.boolean "is_default",                       :default => false, :null => false
    t.integer "position",                         :default => 1
    t.integer "default_done_ratio"
  end

  add_index "statuses", ["is_closed"], :name => "index_issue_statuses_on_is_closed"
  add_index "statuses", ["is_default"], :name => "index_issue_statuses_on_is_default"
  add_index "statuses", ["position"], :name => "index_issue_statuses_on_position"

  create_table "time_entries", :force => true do |t|
    t.integer  "project_id",      :null => false
    t.integer  "user_id",         :null => false
    t.integer  "work_package_id"
    t.float    "hours",           :null => false
    t.string   "comments"
    t.integer  "activity_id",     :null => false
    t.date     "spent_on",        :null => false
    t.integer  "tyear",           :null => false
    t.integer  "tmonth",          :null => false
    t.integer  "tweek",           :null => false
    t.datetime "created_on",      :null => false
    t.datetime "updated_on",      :null => false
  end

  add_index "time_entries", ["activity_id"], :name => "index_time_entries_on_activity_id"
  add_index "time_entries", ["created_on"], :name => "index_time_entries_on_created_on"
  add_index "time_entries", ["project_id"], :name => "time_entries_project_id"
  add_index "time_entries", ["user_id"], :name => "index_time_entries_on_user_id"
  add_index "time_entries", ["work_package_id"], :name => "time_entries_issue_id"

  create_table "time_entry_journals", :force => true do |t|
    t.integer "journal_id",      :null => false
    t.integer "project_id",      :null => false
    t.integer "user_id",         :null => false
    t.integer "work_package_id"
    t.float   "hours",           :null => false
    t.string  "comments"
    t.integer "activity_id",     :null => false
    t.date    "spent_on",        :null => false
    t.integer "tyear",           :null => false
    t.integer "tmonth",          :null => false
    t.integer "tweek",           :null => false
  end

  add_index "time_entry_journals", ["journal_id"], :name => "index_time_entry_journals_on_journal_id"

  create_table "timelines", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "project_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.text     "options"
  end

  add_index "timelines", ["project_id"], :name => "index_timelines_timelines_on_project_id"

  create_table "tokens", :force => true do |t|
    t.integer  "user_id",                  :default => 0,  :null => false
    t.string   "action",     :limit => 30, :default => "", :null => false
    t.string   "value",      :limit => 40, :default => "", :null => false
    t.datetime "created_on",                               :null => false
  end

  add_index "tokens", ["user_id"], :name => "index_tokens_on_user_id"

  create_table "types", :force => true do |t|
    t.string   "name",           :default => "",    :null => false
    t.integer  "position",       :default => 1
    t.boolean  "is_in_roadmap",  :default => true,  :null => false
    t.boolean  "in_aggregation", :default => true,  :null => false
    t.boolean  "is_milestone",   :default => false, :null => false
    t.boolean  "is_default",     :default => false, :null => false
    t.integer  "color_id"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.boolean  "is_standard",    :default => false, :null => false
  end

  add_index "types", ["color_id"], :name => "index_types_on_color_id"

  create_table "user_passwords", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.string   "hashed_password", :limit => 40
    t.string   "salt",            :limit => 64
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "user_passwords", ["user_id"], :name => "index_user_passwords_on_user_id"

  create_table "user_preferences", :force => true do |t|
    t.integer "user_id",   :default => 0,     :null => false
    t.text    "others"
    t.boolean "hide_mail", :default => true
    t.string  "time_zone"
    t.boolean "impaired",  :default => false
  end

  add_index "user_preferences", ["user_id"], :name => "index_user_preferences_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "login",                 :limit => 256, :default => "",    :null => false
    t.string   "firstname",             :limit => 30,  :default => "",    :null => false
    t.string   "lastname",              :limit => 30,  :default => "",    :null => false
    t.string   "mail",                  :limit => 60,  :default => "",    :null => false
    t.boolean  "admin",                                :default => false, :null => false
    t.integer  "status",                               :default => 1,     :null => false
    t.datetime "last_login_on"
    t.string   "language",              :limit => 5,   :default => ""
    t.integer  "auth_source_id"
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "type"
    t.string   "identity_url"
    t.string   "mail_notification",                    :default => "",    :null => false
    t.boolean  "first_login",                          :default => true,  :null => false
    t.boolean  "force_password_change",                :default => false
    t.integer  "failed_login_count",                   :default => 0
    t.datetime "last_failed_login_on"
  end

  add_index "users", ["auth_source_id"], :name => "index_users_on_auth_source_id"
  add_index "users", ["id", "type"], :name => "index_users_on_id_and_type"
  add_index "users", ["type", "login"], :name => "index_users_on_type_and_login"
  add_index "users", ["type", "status"], :name => "index_users_on_type_and_status"
  add_index "users", ["type"], :name => "index_users_on_type"

  create_table "versions", :force => true do |t|
    t.integer  "project_id",      :default => 0,      :null => false
    t.string   "name",            :default => "",     :null => false
    t.string   "description",     :default => ""
    t.date     "effective_date"
    t.datetime "created_on"
    t.datetime "updated_on"
    t.string   "wiki_page_title"
    t.string   "status",          :default => "open"
    t.string   "sharing",         :default => "none", :null => false
    t.date     "start_date"
  end

  add_index "versions", ["project_id"], :name => "versions_project_id"
  add_index "versions", ["sharing"], :name => "index_versions_on_sharing"

  create_table "watchers", :force => true do |t|
    t.string  "watchable_type", :default => "", :null => false
    t.integer "watchable_id",   :default => 0,  :null => false
    t.integer "user_id"
  end

  add_index "watchers", ["user_id", "watchable_type"], :name => "watchers_user_id_type"
  add_index "watchers", ["user_id"], :name => "index_watchers_on_user_id"
  add_index "watchers", ["watchable_id", "watchable_type"], :name => "index_watchers_on_watchable_id_and_watchable_type"

  create_table "wiki_content_journals", :force => true do |t|
    t.integer "journal_id", :null => false
    t.integer "page_id",    :null => false
    t.integer "author_id"
    t.text    "text"
  end

  add_index "wiki_content_journals", ["journal_id"], :name => "index_wiki_content_journals_on_journal_id"

  create_table "wiki_content_versions", :force => true do |t|
    t.integer  "wiki_content_id",                              :null => false
    t.integer  "page_id",                                      :null => false
    t.integer  "author_id"
    t.binary   "data"
    t.string   "compression",     :limit => 6, :default => ""
    t.string   "comments",                     :default => ""
    t.datetime "updated_on",                                   :null => false
    t.integer  "version",                                      :null => false
  end

  add_index "wiki_content_versions", ["updated_on"], :name => "index_wiki_content_versions_on_updated_on"
  add_index "wiki_content_versions", ["wiki_content_id"], :name => "wiki_content_versions_wcid"

  create_table "wiki_contents", :force => true do |t|
    t.integer  "page_id",      :null => false
    t.integer  "author_id"
    t.text     "text"
    t.datetime "updated_on",   :null => false
    t.integer  "lock_version", :null => false
  end

  add_index "wiki_contents", ["author_id"], :name => "index_wiki_contents_on_author_id"
  add_index "wiki_contents", ["page_id"], :name => "wiki_contents_page_id"

  create_table "wiki_pages", :force => true do |t|
    t.integer  "wiki_id",                       :null => false
    t.string   "title",                         :null => false
    t.datetime "created_on",                    :null => false
    t.boolean  "protected",  :default => false, :null => false
    t.integer  "parent_id"
  end

  add_index "wiki_pages", ["parent_id"], :name => "index_wiki_pages_on_parent_id"
  add_index "wiki_pages", ["wiki_id", "title"], :name => "wiki_pages_wiki_id_title"
  add_index "wiki_pages", ["wiki_id"], :name => "index_wiki_pages_on_wiki_id"

  create_table "wiki_redirects", :force => true do |t|
    t.integer  "wiki_id",      :null => false
    t.string   "title"
    t.string   "redirects_to"
    t.datetime "created_on",   :null => false
  end

  add_index "wiki_redirects", ["wiki_id", "title"], :name => "wiki_redirects_wiki_id_title"
  add_index "wiki_redirects", ["wiki_id"], :name => "index_wiki_redirects_on_wiki_id"

  create_table "wikis", :force => true do |t|
    t.integer "project_id",                :null => false
    t.string  "start_page",                :null => false
    t.integer "status",     :default => 1, :null => false
  end

  add_index "wikis", ["project_id"], :name => "wikis_project_id"

  create_table "work_package_journals", :force => true do |t|
    t.integer "journal_id",                       :null => false
    t.integer "type_id",          :default => 0,  :null => false
    t.integer "project_id",       :default => 0,  :null => false
    t.string  "subject",          :default => "", :null => false
    t.text    "description"
    t.date    "due_date"
    t.integer "category_id"
    t.integer "status_id",        :default => 0,  :null => false
    t.integer "assigned_to_id"
    t.integer "priority_id",      :default => 0,  :null => false
    t.integer "fixed_version_id"
    t.integer "author_id",        :default => 0,  :null => false
    t.integer "done_ratio",       :default => 0,  :null => false
    t.float   "estimated_hours"
    t.date    "start_date"
    t.integer "parent_id"
    t.integer "responsible_id"
  end

  add_index "work_package_journals", ["journal_id"], :name => "index_work_package_journals_on_journal_id"

  create_table "work_packages", :force => true do |t|
    t.integer  "type_id",          :default => 0,  :null => false
    t.integer  "project_id",       :default => 0,  :null => false
    t.string   "subject",          :default => "", :null => false
    t.text     "description"
    t.date     "due_date"
    t.integer  "category_id"
    t.integer  "status_id",        :default => 0,  :null => false
    t.integer  "assigned_to_id"
    t.integer  "priority_id",      :default => 0
    t.integer  "fixed_version_id"
    t.integer  "author_id",        :default => 0,  :null => false
    t.integer  "lock_version",     :default => 0,  :null => false
    t.integer  "done_ratio",       :default => 0,  :null => false
    t.float    "estimated_hours"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "start_date"
    t.integer  "parent_id"
    t.integer  "responsible_id"
    t.integer  "root_id"
    t.integer  "lft"
    t.integer  "rgt"
  end

  add_index "work_packages", ["assigned_to_id"], :name => "index_work_packages_on_assigned_to_id"
  add_index "work_packages", ["author_id"], :name => "index_work_packages_on_author_id"
  add_index "work_packages", ["category_id"], :name => "index_work_packages_on_category_id"
  add_index "work_packages", ["created_at"], :name => "index_work_packages_on_created_at"
  add_index "work_packages", ["fixed_version_id"], :name => "index_work_packages_on_fixed_version_id"
  add_index "work_packages", ["parent_id"], :name => "index_work_packages_on_parent_id"
  add_index "work_packages", ["project_id"], :name => "index_work_packages_on_project_id"
  add_index "work_packages", ["responsible_id"], :name => "index_work_packages_on_responsible_id"
  add_index "work_packages", ["root_id", "lft", "rgt"], :name => "index_work_packages_on_root_id_and_lft_and_rgt"
  add_index "work_packages", ["status_id"], :name => "index_work_packages_on_status_id"
  add_index "work_packages", ["type_id"], :name => "index_work_packages_on_type_id"
  add_index "work_packages", ["updated_at"], :name => "index_work_packages_on_updated_at"

  create_table "workflows", :force => true do |t|
    t.integer "type_id",       :default => 0,     :null => false
    t.integer "old_status_id", :default => 0,     :null => false
    t.integer "new_status_id", :default => 0,     :null => false
    t.integer "role_id",       :default => 0,     :null => false
    t.boolean "assignee",      :default => false, :null => false
    t.boolean "author",        :default => false, :null => false
  end

  add_index "workflows", ["new_status_id"], :name => "index_workflows_on_new_status_id"
  add_index "workflows", ["old_status_id"], :name => "index_workflows_on_old_status_id"
  add_index "workflows", ["role_id", "type_id", "old_status_id"], :name => "wkfs_role_type_old_status"
  add_index "workflows", ["role_id"], :name => "index_workflows_on_role_id"

end
