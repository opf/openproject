# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

require 'iconv'

class Changeset < ActiveRecord::Base
  belongs_to :repository
  belongs_to :user
  has_many :changes, :dependent => :delete_all
  has_and_belongs_to_many :issues

  acts_as_event :title => Proc.new {|o| "#{l(:label_revision)} #{o.revision}" + (o.comments.blank? ? '' : (': ' + o.comments))},
                :description => :comments,
                :datetime => :committed_on,
                :url => Proc.new {|o| {:controller => 'repositories', :action => 'revision', :id => o.repository.project_id, :rev => o.revision}}
                
  acts_as_searchable :columns => 'comments',
                     :include => {:repository => :project},
                     :project_key => "#{Repository.table_name}.project_id",
                     :date_column => 'committed_on'
                     
  acts_as_activity_provider :timestamp => "#{table_name}.committed_on",
                            :author_key => :user_id,
                            :find_options => {:include => {:repository => :project}}
  
  validates_presence_of :repository_id, :revision, :committed_on, :commit_date
  validates_uniqueness_of :revision, :scope => :repository_id
  validates_uniqueness_of :scmid, :scope => :repository_id, :allow_nil => true
  
  def revision=(r)
    write_attribute :revision, (r.nil? ? nil : r.to_s)
  end
  
  def comments=(comment)
    write_attribute(:comments, Changeset.normalize_comments(comment))
  end

  def committed_on=(date)
    self.commit_date = date
    super
  end
  
  def project
    repository.project
  end
  
  def author
    user || committer.to_s.split('<').first
  end
  
  def before_create
    self.user = repository.find_committer_user(committer)
  end
  
  def after_create
    scan_comment_for_issue_ids
  end
  require 'pp'
  
  def scan_comment_for_issue_ids
    return if comments.blank?
    # keywords used to reference issues
    ref_keywords = Setting.commit_ref_keywords.downcase.split(",").collect(&:strip)
    # keywords used to fix issues
    fix_keywords = Setting.commit_fix_keywords.downcase.split(",").collect(&:strip)
    # status and optional done ratio applied
    fix_status = IssueStatus.find_by_id(Setting.commit_fix_status_id)
    done_ratio = Setting.commit_fix_done_ratio.blank? ? nil : Setting.commit_fix_done_ratio.to_i
    
    kw_regexp = (ref_keywords + fix_keywords).collect{|kw| Regexp.escape(kw)}.join("|")
    return if kw_regexp.blank?
    
    referenced_issues = []
    
    if ref_keywords.delete('*')
      # find any issue ID in the comments
      target_issue_ids = []
      comments.scan(%r{([\s\(,-]|^)#(\d+)(?=[[:punct:]]|\s|<|$)}).each { |m| target_issue_ids << m[1] }
      referenced_issues += repository.project.issues.find_all_by_id(target_issue_ids)
    end
    
    comments.scan(Regexp.new("(#{kw_regexp})[\s:]+(([\s,;&]*#?\\d+)+)", Regexp::IGNORECASE)).each do |match|
      action = match[0]
      target_issue_ids = match[1].scan(/\d+/)
      target_issues = repository.project.issues.find_all_by_id(target_issue_ids)
      if fix_status && fix_keywords.include?(action.downcase)
        # update status of issues
        logger.debug "Issues fixed by changeset #{self.revision}: #{issue_ids.join(', ')}." if logger && logger.debug?
        target_issues.each do |issue|
          # the issue may have been updated by the closure of another one (eg. duplicate)
          issue.reload
          # don't change the status is the issue is closed
          next if issue.status.is_closed?
          csettext = "r#{self.revision}"
          if self.scmid && (! (csettext =~ /^r[0-9]+$/))
            csettext = "commit:\"#{self.scmid}\""
          end
          journal = issue.init_journal(user || User.anonymous, l(:text_status_changed_by_changeset, csettext))
          issue.status = fix_status
          issue.done_ratio = done_ratio if done_ratio
          issue.save
          Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
        end
      end
      referenced_issues += target_issues
    end
    
    self.issues = referenced_issues.uniq
  end
  
  # Returns the previous changeset
  def previous
    @previous ||= Changeset.find(:first, :conditions => ['id < ? AND repository_id = ?', self.id, self.repository_id], :order => 'id DESC')
  end

  # Returns the next changeset
  def next
    @next ||= Changeset.find(:first, :conditions => ['id > ? AND repository_id = ?', self.id, self.repository_id], :order => 'id ASC')
  end
  
  # Strips and reencodes a commit log before insertion into the database
  def self.normalize_comments(str)
    to_utf8(str.to_s.strip)
  end
  
  private


  def self.to_utf8(str)
    return str if /\A[\r\n\t\x20-\x7e]*\Z/n.match(str) # for us-ascii
    encoding = Setting.commit_logs_encoding.to_s.strip
    unless encoding.blank? || encoding == 'UTF-8'
      begin
        return Iconv.conv('UTF-8', encoding, str)
      rescue Iconv::Failure
        # do nothing here
      end
    end
    str
  end
end
