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

  acts_as_event :title => Proc.new {|o| "#{l(:label_revision)} #{o.format_identifier}" + (o.short_comments.blank? ? '' : (': ' + o.short_comments))},
                :description => :long_comments,
                :datetime => :committed_on,
                :url => Proc.new {|o| {:controller => 'repositories', :action => 'revision', :id => o.repository.project, :rev => o.identifier}}
                
  acts_as_searchable :columns => 'comments',
                     :include => {:repository => :project},
                     :project_key => "#{Repository.table_name}.project_id",
                     :date_column => 'committed_on'
                     
  acts_as_activity_provider :timestamp => "#{table_name}.committed_on",
                            :author_key => :user_id,
                            :find_options => {:include => [:user, {:repository => :project}]}
  
  validates_presence_of :repository_id, :revision, :committed_on, :commit_date
  validates_uniqueness_of :revision, :scope => :repository_id
  validates_uniqueness_of :scmid, :scope => :repository_id, :allow_nil => true
  
  named_scope :visible, lambda {|*args| { :include => {:repository => :project},
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_changesets) } }
                                          
  def revision=(r)
    write_attribute :revision, (r.nil? ? nil : r.to_s)
  end

  # Returns the identifier of this changeset; depending on repository backends
  def identifier
    if repository.class.respond_to? :changeset_identifier
      repository.class.changeset_identifier self
    else
      revision.to_s
    end
  end

  def committed_on=(date)
    self.commit_date = date
    super
  end

  # Returns the readable identifier
  def format_identifier
    if repository.class.respond_to? :format_changeset_identifier
      repository.class.format_changeset_identifier self
    else
      identifier
    end
  end
  
  def project
    repository.project
  end
  
  def author
    user || committer.to_s.split('<').first
  end
  
  def before_create
    self.committer = self.class.to_utf8(self.committer, repository.repo_log_encoding)
    self.comments  = self.class.normalize_comments(self.comments, repository.repo_log_encoding)
    self.user = repository.find_committer_user(self.committer)
  end

  def after_create
    scan_comment_for_issue_ids
  end
  
  TIMELOG_RE = /
    (
    ((\d+)(h|hours?))((\d+)(m|min)?)?
    |
    ((\d+)(h|hours?|m|min))
    |
    (\d+):(\d+)
    |
    (\d+([\.,]\d+)?)h?
    )
    /x
  
  def scan_comment_for_issue_ids
    return if comments.blank?
    # keywords used to reference issues
    ref_keywords = Setting.commit_ref_keywords.downcase.split(",").collect(&:strip)
    ref_keywords_any = ref_keywords.delete('*')
    # keywords used to fix issues
    fix_keywords = Setting.commit_fix_keywords.downcase.split(",").collect(&:strip)
    
    kw_regexp = (ref_keywords + fix_keywords).collect{|kw| Regexp.escape(kw)}.join("|")
    
    referenced_issues = []
    
    comments.scan(/([\s\(\[,-]|^)((#{kw_regexp})[\s:]+)?(#\d+(\s+@#{TIMELOG_RE})?([\s,;&]+#\d+(\s+@#{TIMELOG_RE})?)*)(?=[[:punct:]]|\s|<|$)/i) do |match|
      action, refs = match[2], match[3]
      next unless action.present? || ref_keywords_any
      
      refs.scan(/#(\d+)(\s+@#{TIMELOG_RE})?/).each do |m|
        issue, hours = find_referenced_issue_by_id(m[0].to_i), m[2]
        if issue
          referenced_issues << issue
          fix_issue(issue) if fix_keywords.include?(action.to_s.downcase)
          log_time(issue, hours) if hours && Setting.commit_logtime_enabled?
        end
      end
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

  def text_tag
    if scmid?
      "commit:#{scmid}"
    else
      "r#{revision}"
    end
  end
  
  # Returns the previous changeset
  def previous
    @previous ||= Changeset.find(:first, :conditions => ['id < ? AND repository_id = ?', self.id, self.repository_id], :order => 'id DESC')
  end

  # Returns the next changeset
  def next
    @next ||= Changeset.find(:first, :conditions => ['id > ? AND repository_id = ?', self.id, self.repository_id], :order => 'id ASC')
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

  # Finds an issue that can be referenced by the commit message
  # i.e. an issue that belong to the repository project, a subproject or a parent project
  def find_referenced_issue_by_id(id)
    return nil if id.blank?
    issue = Issue.find_by_id(id.to_i, :include => :project)
    if issue
      unless project == issue.project || project.is_ancestor_of?(issue.project) || project.is_descendant_of?(issue.project)
        issue = nil
      end
    end
    issue
  end
  
  def fix_issue(issue)
    status = IssueStatus.find_by_id(Setting.commit_fix_status_id.to_i)
    if status.nil?
      logger.warn("No status macthes commit_fix_status_id setting (#{Setting.commit_fix_status_id})") if logger
      return issue
    end
    
    # the issue may have been updated by the closure of another one (eg. duplicate)
    issue.reload
    # don't change the status is the issue is closed
    return if issue.status && issue.status.is_closed?
    
    journal = issue.init_journal(user || User.anonymous, ll(Setting.default_language, :text_status_changed_by_changeset, text_tag))
    issue.status = status
    unless Setting.commit_fix_done_ratio.blank?
      issue.done_ratio = Setting.commit_fix_done_ratio.to_i
    end
    Redmine::Hook.call_hook(:model_changeset_scan_commit_for_issue_ids_pre_issue_update,
                            { :changeset => self, :issue => issue })
    unless issue.save
      logger.warn("Issue ##{issue.id} could not be saved by changeset #{id}: #{issue.errors.full_messages}") if logger
    end
    issue
  end
  
  def log_time(issue, hours)
    time_entry = TimeEntry.new(
      :user => user,
      :hours => hours,
      :issue => issue,
      :spent_on => commit_date,
      :comments => l(:text_time_logged_by_changeset, :value => text_tag, :locale => Setting.default_language)
      )
    time_entry.activity = log_time_activity unless log_time_activity.nil?
    
    unless time_entry.save
      logger.warn("TimeEntry could not be created by changeset #{id}: #{time_entry.errors.full_messages}") if logger
    end
    time_entry
  end
  
  def log_time_activity
    if Setting.commit_logtime_activity_id.to_i > 0
      TimeEntryActivity.find_by_id(Setting.commit_logtime_activity_id.to_i)
    end
  end
  
  def split_comments
    comments =~ /\A(.+?)\r?\n(.*)$/m
    @short_comments = $1 || comments
    @long_comments = $2.to_s.strip
    return @short_comments, @long_comments
  end

  public

  # Strips and reencodes a commit log before insertion into the database
  def self.normalize_comments(str, encoding)
    Changeset.to_utf8(str.to_s.strip, encoding)
  end

  private

  def self.to_utf8(str, encoding)
    return str if str.blank?
    unless encoding.blank? || encoding == 'UTF-8'
      begin
        str = Iconv.conv('UTF-8', encoding, str)
      rescue Iconv::Failure
        # do nothing here
      end
    end
    if str.respond_to?(:force_encoding)
      str.force_encoding('UTF-8')
      if ! str.valid_encoding?
        str = str.encode("US-ASCII", :invalid => :replace,
              :undef => :replace, :replace => '?').encode("UTF-8")
      end
    else
      # removes invalid UTF8 sequences
      begin
        str = Iconv.conv('UTF-8//IGNORE', 'UTF-8', str + '  ')[0..-3]
      rescue Iconv::InvalidEncoding
        # "UTF-8//IGNORE" is not supported on some OS
      end
    end
    str
  end
end
