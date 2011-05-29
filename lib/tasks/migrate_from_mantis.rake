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


desc 'Mantis migration script'

require 'active_record'
require 'iconv'
require 'pp'

namespace :redmine do
task :migrate_from_mantis => :environment do
  
  module MantisMigrate
   
      DEFAULT_STATUS = IssueStatus.default
      assigned_status = IssueStatus.find_by_position(2)
      resolved_status = IssueStatus.find_by_position(3)
      feedback_status = IssueStatus.find_by_position(4)
      closed_status = IssueStatus.find :first, :conditions => { :is_closed => true }
      STATUS_MAPPING = {10 => DEFAULT_STATUS,  # new
                        20 => feedback_status, # feedback
                        30 => DEFAULT_STATUS,  # acknowledged
                        40 => DEFAULT_STATUS,  # confirmed
                        50 => assigned_status, # assigned
                        80 => resolved_status, # resolved
                        90 => closed_status    # closed
                        }
                        
      priorities = IssuePriority.all
      DEFAULT_PRIORITY = priorities[2]
      PRIORITY_MAPPING = {10 => priorities[1], # none
                          20 => priorities[1], # low
                          30 => priorities[2], # normal
                          40 => priorities[3], # high
                          50 => priorities[4], # urgent
                          60 => priorities[5]  # immediate
                          }
    
      TRACKER_BUG = Tracker.find_by_position(1)
      TRACKER_FEATURE = Tracker.find_by_position(2)
      
      roles = Role.find(:all, :conditions => {:builtin => 0}, :order => 'position ASC')
      manager_role = roles[0]
      developer_role = roles[1]
      DEFAULT_ROLE = roles.last
      ROLE_MAPPING = {10 => DEFAULT_ROLE,   # viewer
                      25 => DEFAULT_ROLE,   # reporter
                      40 => DEFAULT_ROLE,   # updater
                      55 => developer_role, # developer
                      70 => manager_role,   # manager
                      90 => manager_role    # administrator
                      }
      
      CUSTOM_FIELD_TYPE_MAPPING = {0 => 'string', # String
                                   1 => 'int',    # Numeric
                                   2 => 'int',    # Float
                                   3 => 'list',   # Enumeration
                                   4 => 'string', # Email
                                   5 => 'bool',   # Checkbox
                                   6 => 'list',   # List
                                   7 => 'list',   # Multiselection list
                                   8 => 'date',   # Date
                                   }
                                   
      RELATION_TYPE_MAPPING = {1 => IssueRelation::TYPE_RELATES,    # related to
                               2 => IssueRelation::TYPE_RELATES,    # parent of
                               3 => IssueRelation::TYPE_RELATES,    # child of
                               0 => IssueRelation::TYPE_DUPLICATES, # duplicate of
                               4 => IssueRelation::TYPE_DUPLICATES  # has duplicate
                               }
                                                                   
    class MantisUser < ActiveRecord::Base
      set_table_name :mantis_user_table
      
      def firstname
        @firstname = realname.blank? ? username : realname.split.first[0..29]
        @firstname
      end
      
      def lastname
        @lastname = realname.blank? ? '-' : realname.split[1..-1].join(' ')[0..29]
        @lastname = '-' if @lastname.blank?
        @lastname
      end
      
      def email
        if read_attribute(:email).match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i) &&
             !User.find_by_mail(read_attribute(:email))
          @email = read_attribute(:email)
        else
          @email = "#{username}@foo.bar"
        end
      end
      
      def username
        read_attribute(:username)[0..29].gsub(/[^a-zA-Z0-9_\-@\.]/, '-')
      end
    end
    
    class MantisProject < ActiveRecord::Base
      set_table_name :mantis_project_table
      has_many :versions, :class_name => "MantisVersion", :foreign_key => :project_id
      has_many :categories, :class_name => "MantisCategory", :foreign_key => :project_id
      has_many :news, :class_name => "MantisNews", :foreign_key => :project_id
      has_many :members, :class_name => "MantisProjectUser", :foreign_key => :project_id
      
      def identifier
        read_attribute(:name).gsub(/[^a-z0-9\-]+/, '-').slice(0, Project::IDENTIFIER_MAX_LENGTH)
      end
    end
    
    class MantisVersion < ActiveRecord::Base
      set_table_name :mantis_project_version_table
      
      def version
        read_attribute(:version)[0..29]
      end
      
      def description
        read_attribute(:description)[0..254]
      end
    end
    
    class MantisCategory < ActiveRecord::Base
      set_table_name :mantis_project_category_table
    end
    
    class MantisProjectUser < ActiveRecord::Base
      set_table_name :mantis_project_user_list_table
    end
    
    class MantisBug < ActiveRecord::Base
      set_table_name :mantis_bug_table
      belongs_to :bug_text, :class_name => "MantisBugText", :foreign_key => :bug_text_id
      has_many :bug_notes, :class_name => "MantisBugNote", :foreign_key => :bug_id
      has_many :bug_files, :class_name => "MantisBugFile", :foreign_key => :bug_id
      has_many :bug_monitors, :class_name => "MantisBugMonitor", :foreign_key => :bug_id
    end
    
    class MantisBugText < ActiveRecord::Base
      set_table_name :mantis_bug_text_table
      
      # Adds Mantis steps_to_reproduce and additional_information fields
      # to description if any
      def full_description
        full_description = description
        full_description += "\n\n*Steps to reproduce:*\n\n#{steps_to_reproduce}" unless steps_to_reproduce.blank?
        full_description += "\n\n*Additional information:*\n\n#{additional_information}" unless additional_information.blank?
        full_description
      end
    end
    
    class MantisBugNote < ActiveRecord::Base
      set_table_name :mantis_bugnote_table
      belongs_to :bug, :class_name => "MantisBug", :foreign_key => :bug_id
      belongs_to :bug_note_text, :class_name => "MantisBugNoteText", :foreign_key => :bugnote_text_id
    end
    
    class MantisBugNoteText < ActiveRecord::Base
      set_table_name :mantis_bugnote_text_table
    end
    
    class MantisBugFile < ActiveRecord::Base
      set_table_name :mantis_bug_file_table
      
      def size
        filesize
      end
      
      def original_filename
        MantisMigrate.encode(filename)
      end
      
      def content_type
        file_type
      end
      
      def read(*args)
      	if @read_finished
      		nil
      	else
      		@read_finished = true
      		content
      	end
      end
    end
    
    class MantisBugRelationship < ActiveRecord::Base
      set_table_name :mantis_bug_relationship_table
    end
    
    class MantisBugMonitor < ActiveRecord::Base
      set_table_name :mantis_bug_monitor_table
    end
    
    class MantisNews < ActiveRecord::Base
      set_table_name :mantis_news_table
    end
    
    class MantisCustomField < ActiveRecord::Base
      set_table_name :mantis_custom_field_table
      set_inheritance_column :none  
      has_many :values, :class_name => "MantisCustomFieldString", :foreign_key => :field_id
      has_many :projects, :class_name => "MantisCustomFieldProject", :foreign_key => :field_id
      
      def format
        read_attribute :type
      end
      
      def name
        read_attribute(:name)[0..29]
      end
    end
    
    class MantisCustomFieldProject < ActiveRecord::Base
      set_table_name :mantis_custom_field_project_table  
    end
    
    class MantisCustomFieldString < ActiveRecord::Base
      set_table_name :mantis_custom_field_string_table  
    end
  
  
    def self.migrate
          
      # Users
      print "Migrating users"
      User.delete_all "login <> 'admin'"
      users_map = {}
      users_migrated = 0
      MantisUser.find(:all).each do |user|
    	u = User.new :firstname => encode(user.firstname), 
    				 :lastname => encode(user.lastname),
    				 :mail => user.email,
    				 :last_login_on => user.last_visit
    	u.login = user.username
    	u.password = 'mantis'
    	u.status = User::STATUS_LOCKED if user.enabled != 1
    	u.admin = true if user.access_level == 90
    	next unless u.save!
    	users_migrated += 1
    	users_map[user.id] = u.id
    	print '.'
      end
      puts
    
      # Projects
      print "Migrating projects"
      Project.destroy_all
      projects_map = {}
      versions_map = {}
      categories_map = {}
      MantisProject.find(:all).each do |project|
    	p = Project.new :name => encode(project.name), 
                        :description => encode(project.description)
    	p.identifier = project.identifier
    	next unless p.save
    	projects_map[project.id] = p.id
    	p.enabled_module_names = ['issue_tracking', 'news', 'wiki']
        p.trackers << TRACKER_BUG
        p.trackers << TRACKER_FEATURE
    	print '.'
    	
    	# Project members
    	project.members.each do |member|
          m = Member.new :user => User.find_by_id(users_map[member.user_id]),
    	                   :roles => [ROLE_MAPPING[member.access_level] || DEFAULT_ROLE]
    	  m.project = p
    	  m.save
    	end	
    	
    	# Project versions
    	project.versions.each do |version|
          v = Version.new :name => encode(version.version),
                          :description => encode(version.description),
                          :effective_date => (version.date_order ? version.date_order.to_date : nil)
          v.project = p
          v.save
          versions_map[version.id] = v.id
    	end
    	
    	# Project categories
    	project.categories.each do |category|
          g = IssueCategory.new :name => category.category[0,30]
          g.project = p
          g.save
          categories_map[category.category] = g.id
    	end
      end	
      puts	
    
      # Bugs
      print "Migrating bugs"
      Issue.destroy_all
      issues_map = {}
      keep_bug_ids = (Issue.count == 0)
      MantisBug.find_each(:batch_size => 200) do |bug|
        next unless projects_map[bug.project_id] && users_map[bug.reporter_id]
    	i = Issue.new :project_id => projects_map[bug.project_id], 
                      :subject => encode(bug.summary),
                      :description => encode(bug.bug_text.full_description),
                      :priority => PRIORITY_MAPPING[bug.priority] || DEFAULT_PRIORITY,
                      :created_on => bug.date_submitted,
                      :updated_on => bug.last_updated
    	i.author = User.find_by_id(users_map[bug.reporter_id])
    	i.category = IssueCategory.find_by_project_id_and_name(i.project_id, bug.category[0,30]) unless bug.category.blank?
    	i.fixed_version = Version.find_by_project_id_and_name(i.project_id, bug.fixed_in_version) unless bug.fixed_in_version.blank?
    	i.status = STATUS_MAPPING[bug.status] || DEFAULT_STATUS
    	i.tracker = (bug.severity == 10 ? TRACKER_FEATURE : TRACKER_BUG)
    	i.id = bug.id if keep_bug_ids
    	next unless i.save
    	issues_map[bug.id] = i.id
    	print '.'
      STDOUT.flush

        # Assignee
        # Redmine checks that the assignee is a project member
        if (bug.handler_id && users_map[bug.handler_id])
          i.assigned_to = User.find_by_id(users_map[bug.handler_id])
          i.save_with_validation(false)
        end        
    	
    	# Bug notes
    	bug.bug_notes.each do |note|
    	  next unless users_map[note.reporter_id]
          n = Journal.new :notes => encode(note.bug_note_text.note),
                          :created_on => note.date_submitted
          n.user = User.find_by_id(users_map[note.reporter_id])
          n.journalized = i
          n.save
    	end
    	
        # Bug files
        bug.bug_files.each do |file|
          a = Attachment.new :created_on => file.date_added
          a.file = file
          a.author = User.find :first
          a.container = i
          a.save
        end
        
        # Bug monitors
        bug.bug_monitors.each do |monitor|
          next unless users_map[monitor.user_id]
          i.add_watcher(User.find_by_id(users_map[monitor.user_id]))
        end
      end
      
      # update issue id sequence if needed (postgresql)
      Issue.connection.reset_pk_sequence!(Issue.table_name) if Issue.connection.respond_to?('reset_pk_sequence!')
      puts
      
      # Bug relationships
      print "Migrating bug relations"
      MantisBugRelationship.find(:all).each do |relation|
        next unless issues_map[relation.source_bug_id] && issues_map[relation.destination_bug_id]
        r = IssueRelation.new :relation_type => RELATION_TYPE_MAPPING[relation.relationship_type]
        r.issue_from = Issue.find_by_id(issues_map[relation.source_bug_id])
        r.issue_to = Issue.find_by_id(issues_map[relation.destination_bug_id])
        pp r unless r.save
        print '.'
        STDOUT.flush
      end
      puts
      
      # News
      print "Migrating news"
      News.destroy_all
      MantisNews.find(:all, :conditions => 'project_id > 0').each do |news|
        next unless projects_map[news.project_id]
        n = News.new :project_id => projects_map[news.project_id],
                     :title => encode(news.headline[0..59]),
                     :description => encode(news.body),
                     :created_on => news.date_posted
        n.author = User.find_by_id(users_map[news.poster_id])
        n.save
        print '.'
        STDOUT.flush
      end
      puts
      
      # Custom fields
      print "Migrating custom fields"
      IssueCustomField.destroy_all
      MantisCustomField.find(:all).each do |field|
        f = IssueCustomField.new :name => field.name[0..29],
                                 :field_format => CUSTOM_FIELD_TYPE_MAPPING[field.format],
                                 :min_length => field.length_min,
                                 :max_length => field.length_max,
                                 :regexp => field.valid_regexp,
                                 :possible_values => field.possible_values.split('|'),
                                 :is_required => field.require_report?
        next unless f.save
        print '.'
        STDOUT.flush
        # Trackers association
        f.trackers = Tracker.find :all
        
        # Projects association
        field.projects.each do |project|
          f.projects << Project.find_by_id(projects_map[project.project_id]) if projects_map[project.project_id]
        end
        
        # Values
        field.values.each do |value|
          v = CustomValue.new :custom_field_id => f.id,
                              :value => value.value
          v.customized = Issue.find_by_id(issues_map[value.bug_id]) if issues_map[value.bug_id]
          v.save
        end unless f.new_record?
      end
      puts
    
      puts
      puts "Users:           #{users_migrated}/#{MantisUser.count}"
      puts "Projects:        #{Project.count}/#{MantisProject.count}"
      puts "Memberships:     #{Member.count}/#{MantisProjectUser.count}"
      puts "Versions:        #{Version.count}/#{MantisVersion.count}"
      puts "Categories:      #{IssueCategory.count}/#{MantisCategory.count}"
      puts "Bugs:            #{Issue.count}/#{MantisBug.count}"
      puts "Bug notes:       #{Journal.count}/#{MantisBugNote.count}"
      puts "Bug files:       #{Attachment.count}/#{MantisBugFile.count}"
      puts "Bug relations:   #{IssueRelation.count}/#{MantisBugRelationship.count}"
      puts "Bug monitors:    #{Watcher.count}/#{MantisBugMonitor.count}"
      puts "News:            #{News.count}/#{MantisNews.count}"
      puts "Custom fields:   #{IssueCustomField.count}/#{MantisCustomField.count}"
    end
  
    def self.encoding(charset)
      @ic = Iconv.new('UTF-8', charset)
    rescue Iconv::InvalidEncoding
      return false      
    end
    
    def self.establish_connection(params)
      constants.each do |const|
        klass = const_get(const)
        next unless klass.respond_to? 'establish_connection'
        klass.establish_connection params
      end
    end
    
    def self.encode(text)
      @ic.iconv text
    rescue
      text
    end
  end
  
  puts
  if Redmine::DefaultData::Loader.no_data?
    puts "Redmine configuration need to be loaded before importing data."
    puts "Please, run this first:"
    puts
    puts "  rake redmine:load_default_data RAILS_ENV=\"#{ENV['RAILS_ENV']}\""
    exit
  end
  
  puts "WARNING: Your Redmine data will be deleted during this process."
  print "Are you sure you want to continue ? [y/N] "
  STDOUT.flush
  break unless STDIN.gets.match(/^y$/i)
  
  # Default Mantis database settings
  db_params = {:adapter => 'mysql', 
               :database => 'bugtracker', 
               :host => 'localhost', 
               :username => 'root', 
               :password => '' }

  puts				
  puts "Please enter settings for your Mantis database"  
  [:adapter, :host, :database, :username, :password].each do |param|
    print "#{param} [#{db_params[param]}]: "
    value = STDIN.gets.chomp!
    db_params[param] = value unless value.blank?
  end
    
  while true
    print "encoding [UTF-8]: "
    STDOUT.flush
    encoding = STDIN.gets.chomp!
    encoding = 'UTF-8' if encoding.blank?
    break if MantisMigrate.encoding encoding
    puts "Invalid encoding!"
  end
  puts
  
  # Make sure bugs can refer bugs in other projects
  Setting.cross_project_issue_relations = 1 if Setting.respond_to? 'cross_project_issue_relations'
  
  # Turn off email notifications
  Setting.notified_events = []
  
  MantisMigrate.establish_connection db_params
  MantisMigrate.migrate
end
end
