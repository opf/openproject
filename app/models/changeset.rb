# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
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

  acts_as_journalized :event_title => Proc.new {|o| "#{l(:label_revision)} #{o.revision}" + (o.short_comments.blank? ? '' : (': ' + o.short_comments))},
                :event_description => :long_comments,
                :event_datetime => :committed_on,
                :event_url => Proc.new {|o| {:controller => 'repositories', :action => 'revision', :id => o.repository.project, :rev => o.revision}},
                :activity_timestamp => "#{table_name}.committed_on",
                :activity_find_options => {:include => [:user, {:repository => :project}]}

  acts_as_searchable :columns => 'comments',
                     :include => {:repository => :project},
                     :project_key => "#{Repository.table_name}.project_id",
                     :date_column => 'committed_on'

  validates_presence_of :repository_id, :revision, :committed_on, :commit_date
  validates_uniqueness_of :revision, :scope => :repository_id
  validates_uniqueness_of :scmid, :scope => :repository_id, :allow_nil => true
  
  named_scope :visible, lambda {|*args| { :include => {:repository => :project},
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_changesets) } }
                                          
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
  
  def committer=(arg)
    write_attribute(:committer, self.class.to_utf8(arg.to_s))
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
  
  def scan_comment_for_issue_ids
    return if comments.blank?
    # keywords used to reference issues
    ref_keywords = Setting.commit_ref_keywords.downcase.split(",").collect(&:strip)
    # keywords used to fix issues
    fix_keywords = Setting.commit_fix_keywords.downcase.split(",").collect(&:strip)
    
    kw_regexp = (ref_keywords + fix_keywords).collect{|kw| Regexp.escape(kw)}.join("|")
    return if kw_regexp.blank?
    
    referenced_issues = []
    
    if ref_keywords.delete('*')
      # find any issue ID in the comments
      target_issue_ids = []
      comments.scan(%r{([\s\(\[,-]|^)#(\d+)(?=[[:punct:]]|\s|<|$)}).each { |m| target_issue_ids << m[1] }
      referenced_issues += find_referenced_issues_by_id(target_issue_ids)
    end
    
    comments.scan(Regexp.new("(#{kw_regexp})[\s:]+(([\s,;&]*#?\\d+)+)", Regexp::IGNORECASE)).each do |match|
      action = match[0]
      target_issue_ids = match[1].scan(/\d+/)
      target_issues = find_referenced_issues_by_id(target_issue_ids)
      if fix_keywords.include?(action.downcase) && fix_status = IssueStatus.find_by_id(Setting.commit_fix_status_id)
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
          issue.init_journal(user || User.anonymous, ll(Setting.default_language, :text_status_changed_by_changeset, csettext))
          issue.status = fix_status
          unless Setting.commit_fix_done_ratio.blank?
            issue.done_ratio = Setting.commit_fix_done_ratio.to_i
          end
          Redmine::Hook.call_hook(:model_changeset_scan_commit_for_issue_ids_pre_issue_update,
                                  { :changeset => self, :issue => issue })
          issue.save
        end
      end
      referenced_issues += target_issues
    end
    
    referenced_issues.uniq!
    self.issues = referenced_issues unless referenced_issues.empty?
  end
  
  def short_comments
    @short_comments || split_comments.first
  end
  
  def long_comments
    @long_comments || split_comments.last
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

  # Creates a new Change from it's common parameters
  def create_change(change)
    Change.create(:changeset => self,
                  :action => change[:action],
                  :path => change[:path],
                  :from_path => change[:from_path],
                  :from_revision => change[:from_revision])
  end
  
  private

  # Finds issues that can be referenced by the commit message
  # i.e. issues that belong to the repository project, a subproject or a parent project
  def find_referenced_issues_by_id(ids)
    return [] if ids.compact.empty?
    Issue.find_all_by_id(ids, :include => :project).select {|issue|
      project == issue.project || project.is_ancestor_of?(issue.project) || project.is_descendant_of?(issue.project)
    }
  end
  
  def split_comments
    comments =~ /\A(.+?)\r?\n(.*)$/m
    @short_comments = $1 || comments
    @long_comments = $2.to_s.strip
    return @short_comments, @long_comments
  end

  def self.to_utf8(str)
    return str if /\A[\r\n\t\x20-\x7e]*\Z/n.match(str) # for us-ascii
    encoding = Setting.commit_logs_encoding.to_s.strip
    unless encoding.blank? || encoding == 'UTF-8'
      begin
        str = Iconv.conv('UTF-8', encoding, str)
      rescue Iconv::Failure
        # do nothing here
      end
    end
    # removes invalid UTF8 sequences
    begin
      Iconv.conv('UTF-8//IGNORE', 'UTF-8', str + '  ')[0..-3]
    rescue Iconv::InvalidEncoding
      # "UTF-8//IGNORE" is not supported on some OS
      str
    end
  end
end
