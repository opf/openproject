# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require 'active_record'
require 'iconv'
require 'pp'

namespace :redmine do
  desc 'Trac migration script'
  task :migrate_from_trac => :environment do
    
    module TracMigrate
     
        DEFAULT_STATUS = IssueStatus.default
        assigned_status = IssueStatus.find_by_position(2)
        resolved_status = IssueStatus.find_by_position(3)
        feedback_status = IssueStatus.find_by_position(4)
        closed_status = IssueStatus.find :first, :conditions => { :is_closed => true }
        STATUS_MAPPING = {'new' => DEFAULT_STATUS,
                          'reopened' => feedback_status,
                          'assigned' => assigned_status,
                          'closed' => closed_status
                          }
                          
        priorities = Enumeration.get_values('IPRI')
        DEFAULT_PRIORITY = priorities[0]
        PRIORITY_MAPPING = {'lowest' => priorities[0],
                            'low' => priorities[0],
                            'normal' => priorities[1],
                            'high' => priorities[2],
                            'highest' => priorities[3]
                            }
      
        TRACKER_BUG = Tracker.find_by_position(1)
        TRACKER_FEATURE = Tracker.find_by_position(2)
        DEFAULT_TRACKER = TRACKER_BUG
        TRACKER_MAPPING = {'defect' => TRACKER_BUG,
                           'enhancement' => TRACKER_FEATURE,
                           'task' => TRACKER_FEATURE,
                           'patch' =>TRACKER_FEATURE
                           }
                            
        DEFAULT_ROLE = Role.find_by_position(3)
        manager_role = Role.find_by_position(1)
        developer_role = Role.find_by_position(2)
        ROLE_MAPPING = {'admin' => manager_role,
                        'developer' => developer_role
                        }
      
      class TracComponent < ActiveRecord::Base
        set_table_name :component
      end
  
      class TracMilestone < ActiveRecord::Base
        set_table_name :milestone
        
        def due
          if read_attribute(:due) > 0
            Time.at(read_attribute(:due)).to_date
          else
            nil
          end
        end
      end
      
      class TracTicketCustom < ActiveRecord::Base
        set_table_name :ticket_custom
      end
      
      class TracAttachment < ActiveRecord::Base
        set_table_name :attachment
        set_inheritance_column :none
        
        def time; Time.at(read_attribute(:time)) end
        
        def original_filename
          filename
        end
        
        def content_type
          Redmine::MimeType.of(filename) || ''
        end
        
        def exist?
          File.file? trac_fullpath
        end
        
        def read
          File.open("#{trac_fullpath}", 'rb').read
        end
        
      private
        def trac_fullpath
          attachment_type = read_attribute(:type)
          trac_file = filename.gsub( /[^a-zA-Z0-9\-_\.!~*']/n ) {|x| sprintf('%%%02x', x[0]) }
          "#{TracMigrate.trac_attachments_directory}/#{attachment_type}/#{id}/#{trac_file}"
        end
      end
      
      class TracTicket < ActiveRecord::Base
        set_table_name :ticket
        set_inheritance_column :none
        
        # ticket changes: only migrate status changes and comments
        has_many :changes, :class_name => "TracTicketChange", :foreign_key => :ticket
        has_many :attachments, :class_name => "TracAttachment", :foreign_key => :id, :conditions => "#{TracMigrate::TracAttachment.table_name}.type = 'ticket'"
        has_many :customs, :class_name => "TracTicketCustom", :foreign_key => :ticket
        
        def ticket_type
          read_attribute(:type)
        end
        
        def summary
          read_attribute(:summary).blank? ? "(no subject)" : read_attribute(:summary)
        end
        
        def description
          read_attribute(:description).blank? ? summary : read_attribute(:description)
        end
        
        def time; Time.at(read_attribute(:time)) end
      end
      
      class TracTicketChange < ActiveRecord::Base
        set_table_name :ticket_change
        
        def time; Time.at(read_attribute(:time)) end
      end
      
      class TracWikiPage < ActiveRecord::Base
        set_table_name :wiki  
      end
      
      class TracPermission < ActiveRecord::Base
        set_table_name :permission  
      end
      
      def self.find_or_create_user(username, project_member = false)
        u = User.find_by_login(username)
        if !u
          # Create a new user if not found
          mail = username[0,limit_for(User, 'mail')]
          mail = "#{mail}@foo.bar" unless mail.include?("@")
          u = User.new :firstname => username[0,limit_for(User, 'firstname')].gsub(/[^\w\s\'\-]/i, '-'),
                       :lastname => '-',
                       :mail => mail.gsub(/[^-@a-z0-9\.]/i, '-')
          u.login = username[0,limit_for(User, 'login')].gsub(/[^a-z0-9_\-@\.]/i, '-')
          u.password = 'trac'
          u.admin = true if TracPermission.find_by_username_and_action(username, 'admin')
          # finally, a default user is used if the new user is not valid
          u = User.find(:first) unless u.save
        end
        # Make sure he is a member of the project
        if project_member && !u.member_of?(@target_project)
          role = DEFAULT_ROLE
          if u.admin
            role = ROLE_MAPPING['admin']
          elsif TracPermission.find_by_username_and_action(username, 'developer')
            role = ROLE_MAPPING['developer']
          end
          Member.create(:user => u, :project => @target_project, :role => DEFAULT_ROLE)
          u.reload
        end
        u
      end
      
      # Basic wiki syntax conversion
      def self.convert_wiki_text(text)
        # Titles
        text = text.gsub(/^(\=+)\s(.+)\s(\=+)/) {|s| "h#{$1.length}. #{$2}\n"}
        # Links
        text = text.gsub(/\[(http[^\s]+)\s+([^\]]+)\]/) {|s| "\"#{$2}\":#{$1}"}
        # Revisions links
        text = text.gsub(/\[(\d+)\]/, 'r\1')
        text
      end
    
      def self.migrate
        establish_connection({:adapter => trac_adapter, 
                              :database => trac_db_path})

        # Quick database test before clearing Redmine data
        TracComponent.count
        
        puts "Deleting data"
        CustomField.destroy_all
        Issue.destroy_all
        IssueCategory.destroy_all
        Version.destroy_all
        User.destroy_all "login <> 'admin'"
        
        migrated_components = 0
        migrated_milestones = 0
        migrated_tickets = 0
        migrated_custom_values = 0
        migrated_ticket_attachments = 0
        migrated_wiki_edits = 0      
  
        # Components
        print "Migrating components"
        issues_category_map = {}
        TracComponent.find(:all).each do |component|
      	print '.'
          c = IssueCategory.new :project => @target_project,
                                :name => encode(component.name[0, limit_for(IssueCategory, 'name')])
      	next unless c.save
      	issues_category_map[component.name] = c
      	migrated_components += 1
        end
        puts
        
        # Milestones
        print "Migrating milestones"
        version_map = {}
        TracMilestone.find(:all).each do |milestone|
          print '.'
          v = Version.new :project => @target_project,
                          :name => encode(milestone.name[0, limit_for(Version, 'name')]),
                          :description => encode(milestone.description[0, limit_for(Version, 'description')]),
                          :effective_date => milestone.due
          next unless v.save
          version_map[milestone.name] = v
          migrated_milestones += 1
        end
        puts
        
        # Custom fields
        # TODO: read trac.ini instead
        print "Migrating custom fields"
        custom_field_map = {}
        TracTicketCustom.find_by_sql("SELECT DISTINCT name FROM #{TracTicketCustom.table_name}").each do |field|
          print '.'
          f = IssueCustomField.new :name => encode(field.name[0, limit_for(IssueCustomField, 'name')]).humanize,
                                   :field_format => 'string'
          next unless f.save
          f.trackers = Tracker.find(:all)
          f.projects << @target_project
          custom_field_map[field.name] = f
        end
        puts
        
        # Trac 'resolution' field as a Redmine custom field
        r = IssueCustomField.new :name => 'Resolution',
                                 :field_format => 'list',
                                 :is_filter => true
        r.trackers = Tracker.find(:all)
        r.projects << @target_project
        r.possible_values = %w(fixed invalid wontfix duplicate worksforme)
        custom_field_map['resolution'] = r if r.save
            
        # Tickets
        print "Migrating tickets"
          TracTicket.find(:all).each do |ticket|
        	print '.'
        	i = Issue.new :project => @target_project, 
                          :subject => encode(ticket.summary[0, limit_for(Issue, 'subject')]),
                          :description => convert_wiki_text(encode(ticket.description)),
                          :priority => PRIORITY_MAPPING[ticket.priority] || DEFAULT_PRIORITY,
                          :created_on => ticket.time
        	i.author = find_or_create_user(ticket.reporter)    	
        	i.category = issues_category_map[ticket.component] unless ticket.component.blank?
        	i.fixed_version = version_map[ticket.milestone] unless ticket.milestone.blank?
        	i.status = STATUS_MAPPING[ticket.status] || DEFAULT_STATUS
        	i.tracker = TRACKER_MAPPING[ticket.ticket_type] || DEFAULT_TRACKER
        	i.id = ticket.id
        	i.custom_values << CustomValue.new(:custom_field => custom_field_map['resolution'], :value => ticket.resolution) unless ticket.resolution.blank?
        	next unless i.save
        	migrated_tickets += 1
        	
        	# Owner
            unless ticket.owner.blank?
              i.assigned_to = find_or_create_user(ticket.owner, true)
              i.save
            end
      	
        	# Comments and status/resolution changes
        	ticket.changes.group_by(&:time).each do |time, changeset|
              status_change = changeset.select {|change| change.field == 'status'}.first
              resolution_change = changeset.select {|change| change.field == 'resolution'}.first
              comment_change = changeset.select {|change| change.field == 'comment'}.first
              
              n = Journal.new :notes => (comment_change ? convert_wiki_text(encode(comment_change.newvalue)) : ''),
                              :created_on => time
              n.user = find_or_create_user(changeset.first.author)
              n.journalized = i
              if status_change && 
                   STATUS_MAPPING[status_change.oldvalue] &&
                   STATUS_MAPPING[status_change.newvalue] &&
                   (STATUS_MAPPING[status_change.oldvalue] != STATUS_MAPPING[status_change.newvalue])
                n.details << JournalDetail.new(:property => 'attr',
                                               :prop_key => 'status_id',
                                               :old_value => STATUS_MAPPING[status_change.oldvalue].id,
                                               :value => STATUS_MAPPING[status_change.newvalue].id)
              end
              if resolution_change
                n.details << JournalDetail.new(:property => 'cf',
                                               :prop_key => custom_field_map['resolution'].id,
                                               :old_value => resolution_change.oldvalue,
                                               :value => resolution_change.newvalue)
              end
              n.save unless n.details.empty? && n.notes.blank?
        	end
        	
        	# Attachments
        	ticket.attachments.each do |attachment|
        	  next unless attachment.exist?
              a = Attachment.new :created_on => attachment.time
              a.file = attachment
              a.author = find_or_create_user(attachment.author)
              a.container = i
              migrated_ticket_attachments += 1 if a.save
        	end
        	
        	# Custom fields
        	ticket.customs.each do |custom|
              v = CustomValue.new :custom_field => custom_field_map[custom.name],
                                  :value => custom.value
              v.customized = i
              next unless v.save
              migrated_custom_values += 1
        	end
        end
        puts
        
        # Wiki      
        print "Migrating wiki"
        @target_project.wiki.destroy if @target_project.wiki
        @target_project.reload
        wiki = Wiki.new(:project => @target_project, :start_page => 'WikiStart')
        if wiki.save
          TracWikiPage.find(:all, :order => 'name, version').each do |page|
            print '.'
            p = wiki.find_or_new_page(page.name)
            p.content = WikiContent.new(:page => p) if p.new_record?
            p.content.text = page.text
            p.content.author = find_or_create_user(page.author) unless page.author.blank? || page.author == 'trac'
            p.content.comments = page.comment
            p.new_record? ? p.save : p.content.save
            migrated_wiki_edits += 1 unless p.content.new_record?
          end
          
          wiki.reload
          wiki.pages.each do |page|
            page.content.text = convert_wiki_text(page.content.text)
            page.content.save
          end
        end
        puts
        
        puts
        puts "Components:      #{migrated_components}/#{TracComponent.count}"
        puts "Milestones:      #{migrated_milestones}/#{TracMilestone.count}"
        puts "Tickets:         #{migrated_tickets}/#{TracTicket.count}"
        puts "Ticket files:    #{migrated_ticket_attachments}/" + TracAttachment.count("type = 'ticket'").to_s
        puts "Custom values:   #{migrated_custom_values}/#{TracTicketCustom.count}"
        puts "Wiki edits:      #{migrated_wiki_edits}/#{TracWikiPage.count}"
      end
      
      def self.limit_for(klass, attribute)
        klass.columns_hash[attribute.to_s].limit
      end
      
      def self.encoding(charset)
        @ic = Iconv.new('UTF-8', charset)
      rescue Iconv::InvalidEncoding
        puts "Invalid encoding!"
        return false
      end
      
      def self.set_trac_directory(path)
        @trac_directory = path
        raise "This directory doesn't exist!" unless File.directory?(path)
        raise "#{trac_db_path} doesn't exist!" unless File.exist?(trac_db_path)
        raise "#{trac_attachments_directory} doesn't exist!" unless File.directory?(trac_attachments_directory)
        @trac_directory
      rescue Exception => e
        puts e
        return false
      end

      def self.trac_directory
        @trac_directory
      end

      def self.set_trac_adapter(adapter)
        return false unless %w(sqlite sqlite3).include?(adapter)
        @trac_adapter = adapter
      end
      
      def self.trac_adapter; @trac_adapter end
      def self.trac_db_path; "#{trac_directory}/db/trac.db" end
      def self.trac_attachments_directory; "#{trac_directory}/attachments" end
      
      def self.target_project_identifier(identifier)
        project = Project.find_by_identifier(identifier)        
        if !project
          # create the target project
          project = Project.new :name => identifier.humanize,
                                :description => identifier.humanize
          project.identifier = identifier
          puts "Unable to create a project with identifier '#{identifier}'!" unless project.save
          # enable issues and wiki for the created project
          project.enabled_module_names = ['issue_tracking', 'wiki']
        end        
        @target_project = project.new_record? ? nil : project
      end
      
      def self.establish_connection(params)
        constants.each do |const|
          klass = const_get(const)
          next unless klass.respond_to? 'establish_connection'
          klass.establish_connection params
        end
      end
      
    private
      def self.encode(text)
        @ic.iconv text
      rescue
        text
      end
    end
    
    puts
    puts "WARNING: Your Redmine data will be deleted during this process."
    print "Are you sure you want to continue ? [y/N] "
    break unless STDIN.gets.match(/^y$/i)  
    puts

    def prompt(text, options = {}, &block)
      default = options[:default] || ''
      while true
        print "#{text} [#{default}]: "
        value = STDIN.gets.chomp!
        value = default if value.blank?
        break if yield value
      end
    end
    
    prompt('Trac directory') {|directory| TracMigrate.set_trac_directory directory}
    prompt('Trac database adapter (sqlite, sqlite3)', :default => 'sqlite') {|adapter| TracMigrate.set_trac_adapter adapter}
    prompt('Trac database encoding', :default => 'UTF-8') {|encoding| TracMigrate.encoding encoding}
    prompt('Target project identifier') {|identifier| TracMigrate.target_project_identifier identifier}
    puts
    
    TracMigrate.migrate
  end
end
