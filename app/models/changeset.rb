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

class Changeset < ActiveRecord::Base
  belongs_to :repository
  has_many :changes, :dependent => :delete_all
  has_and_belongs_to_many :issues

  acts_as_event :title => Proc.new {|o| "#{l(:label_revision)} #{o.revision}" + (o.comments.blank? ? '' : (': ' + o.comments))},
                :description => :comments,
                :datetime => :committed_on,
                :author => :committer,
                :url => Proc.new {|o| {:controller => 'repositories', :action => 'revision', :id => o.repository.project_id, :rev => o.revision}}
                
  acts_as_searchable :columns => 'comments',
                     :include => :repository,
                     :project_key => "#{Repository.table_name}.project_id",
                     :date_column => 'committed_on'
  
  validates_presence_of :repository_id, :revision, :committed_on, :commit_date
  validates_numericality_of :revision, :only_integer => true
  validates_uniqueness_of :revision, :scope => :repository_id
  validates_uniqueness_of :scmid, :scope => :repository_id, :allow_nil => true
  
  def comments=(comment)
    write_attribute(:comments, comment.strip)
  end

  def committed_on=(date)
    self.commit_date = date
    super
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
    # status and optional done ratio applied
    fix_status = IssueStatus.find_by_id(Setting.commit_fix_status_id)
    done_ratio = Setting.commit_fix_done_ratio.blank? ? nil : Setting.commit_fix_done_ratio.to_i
    
    kw_regexp = (ref_keywords + fix_keywords).collect{|kw| Regexp.escape(kw)}.join("|")
    return if kw_regexp.blank?
    
    referenced_issues = []
    
    if ref_keywords.delete('*')
      # find any issue ID in the comments
      target_issue_ids = []
      comments.scan(%r{([\s\(,-^])#(\d+)(?=[[:punct:]]|\s|<|$)}).each { |m| target_issue_ids << m[1] }
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
          # don't change the status is the issue is already closed
          next if issue.status.is_closed?
          issue.status = fix_status
          issue.done_ratio = done_ratio if done_ratio
          issue.save
        end
      end
      referenced_issues += target_issues
    end
    
    self.issues = referenced_issues.uniq
  end

  # Returns the previous changeset
  def previous
    @previous ||= Changeset.find(:first, :conditions => ['revision < ? AND repository_id = ?', self.revision, self.repository_id], :order => 'revision DESC')
  end

  # Returns the next changeset
  def next
    @next ||= Changeset.find(:first, :conditions => ['revision > ? AND repository_id = ?', self.revision, self.repository_id], :order => 'revision ASC')
  end
end
