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

require 'diff'
require 'enumerator'

class WikiPage < ActiveRecord::Base
  belongs_to :wiki
  has_one :content, :class_name => 'WikiContent', :foreign_key => 'page_id', :dependent => :destroy
  acts_as_attachable :delete_permission => :delete_wiki_pages_attachments
  acts_as_tree :dependent => :nullify, :order => 'title'

  acts_as_watchable
  acts_as_event :title => Proc.new {|o| "#{l(:label_wiki)}: #{o.title}"},
                :description => :text,
                :datetime => :created_on,
                :url => Proc.new {|o| {:controller => 'wiki', :action => 'show', :project_id => o.wiki.project, :id => o.title}}

  acts_as_searchable :columns => ["#{WikiPage.table_name}.title", "#{WikiContent.table_name}.text"],
                     :include => [{:wiki => :project}, :content],
                     :project_key => "#{Wiki.table_name}.project_id"

  attr_accessor :redirect_existing_links

  validates_presence_of :title
  validates_format_of :title, :with => /^[^,\.\/\?\;\|\s]*$/
  validates_uniqueness_of :title, :scope => :wiki_id, :case_sensitive => false
  validates_associated :content

  # eager load information about last updates, without loading text
  named_scope :with_updated_on, {
    :select => "#{WikiPage.table_name}.*, #{WikiContent.table_name}.updated_on",
    :joins => "LEFT JOIN #{WikiContent.table_name} ON #{WikiContent.table_name}.page_id = #{WikiPage.table_name}.id"
  }

  # Wiki pages that are protected by default
  DEFAULT_PROTECTED_PAGES = %w(sidebar)

  def after_initialize
    if new_record? && DEFAULT_PROTECTED_PAGES.include?(title.to_s.downcase)
      self.protected = true
    end
  end

  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:view_wiki_pages, project)
  end

  def title=(value)
    value = Wiki.titleize(value)
    @previous_title = read_attribute(:title) if @previous_title.blank?
    write_attribute(:title, value)
  end

  def before_save
    self.title = Wiki.titleize(title)
    # Manage redirects if the title has changed
    if !@previous_title.blank? && (@previous_title != title) && !new_record?
      # Update redirects that point to the old title
      wiki.redirects.find_all_by_redirects_to(@previous_title).each do |r|
        r.redirects_to = title
        r.title == r.redirects_to ? r.destroy : r.save
      end
      # Remove redirects for the new title
      wiki.redirects.find_all_by_title(title).each(&:destroy)
      # Create a redirect to the new title
      wiki.redirects << WikiRedirect.new(:title => @previous_title, :redirects_to => title) unless redirect_existing_links == "0"
      @previous_title = nil
    end
  end

  def before_destroy
    # Remove redirects to this page
    wiki.redirects.find_all_by_redirects_to(title).each(&:destroy)
  end

  def pretty_title
    WikiPage.pretty_title(title)
  end

  def content_for_version(version=nil)
    result = content.versions.find_by_version(version.to_i) if version
    result ||= content
    result
  end

  def diff(version_to=nil, version_from=nil)
    version_to = version_to ? version_to.to_i : self.content.version
    version_from = version_from ? version_from.to_i : version_to - 1
    version_to, version_from = version_from, version_to unless version_from < version_to

    content_to = content.versions.find_by_version(version_to)
    content_from = content.versions.find_by_version(version_from)

    (content_to && content_from) ? WikiDiff.new(content_to, content_from) : nil
  end

  def annotate(version=nil)
    version = version ? version.to_i : self.content.version
    c = content.versions.find_by_version(version)
    c ? WikiAnnotate.new(c) : nil
  end

  def self.pretty_title(str)
    (str && str.is_a?(String)) ? str.tr('_', ' ') : str
  end

  def project
    wiki.project
  end

  def text
    content.text if content
  end

  def updated_on
    unless @updated_on
      if time = read_attribute(:updated_on)
        # content updated_on was eager loaded with the page
        unless time.is_a? Time
          time = Time.parse(time) rescue nil
        end
        @updated_on = time
      else
        @updated_on = content && content.updated_on
      end
    end
    @updated_on
  end

  # Returns true if usr is allowed to edit the page, otherwise false
  def editable_by?(usr)
    !protected? || usr.allowed_to?(:protect_wiki_pages, wiki.project)
  end

  def attachments_deletable?(usr=User.current)
    editable_by?(usr) && super(usr)
  end

  def parent_title
    @parent_title || (self.parent && self.parent.pretty_title)
  end

  def parent_title=(t)
    @parent_title = t
    parent_page = t.blank? ? nil : self.wiki.find_page(t)
    self.parent = parent_page
  end

  protected

  def validate
    errors.add(:parent_title, :invalid) if !@parent_title.blank? && parent.nil?
    errors.add(:parent_title, :circular_dependency) if parent && (parent == self || parent.ancestors.include?(self))
    errors.add(:parent_title, :not_same_project) if parent && (parent.wiki_id != wiki_id)
  end
end

class WikiDiff < Redmine::Helpers::Diff
  attr_reader :content_to, :content_from

  def initialize(content_to, content_from)
    @content_to = content_to
    @content_from = content_from
    super(content_to.text, content_from.text)
  end
end

class WikiAnnotate
  attr_reader :lines, :content

  def initialize(content)
    @content = content
    current = content
    current_lines = current.text.split(/\r?\n/)
    @lines = current_lines.collect {|t| [nil, nil, t]}
    positions = []
    current_lines.size.times {|i| positions << i}
    while (current.previous)
      d = current.previous.text.split(/\r?\n/).diff(current.text.split(/\r?\n/)).diffs.flatten
      d.each_slice(3) do |s|
        sign, line = s[0], s[1]
        if sign == '+' && positions[line] && positions[line] != -1
          if @lines[positions[line]][0].nil?
            @lines[positions[line]][0] = current.version
            @lines[positions[line]][1] = current.author
          end
        end
      end
      d.each_slice(3) do |s|
        sign, line = s[0], s[1]
        if sign == '-'
          positions.insert(line, -1)
        else
          positions[line] = nil
        end
      end
      positions.compact!
      # Stop if every line is annotated
      break unless @lines.detect { |line| line[0].nil? }
      current = current.previous
    end
    @lines.each { |line| line[0] ||= current.version }
  end
end
