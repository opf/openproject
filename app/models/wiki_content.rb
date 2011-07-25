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

require 'zlib'

class WikiContent < ActiveRecord::Base
  belongs_to :page, :class_name => 'WikiPage', :foreign_key => 'page_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  validates_presence_of :text
  validates_length_of :comments, :maximum => 255, :allow_nil => true

  attr_accessor :comments

  before_save :comments_to_journal_notes

  acts_as_journalized :event_type => 'wiki-page',
    :event_title => Proc.new {|o| "#{l(:label_wiki_edit)}: #{o.page.title} (##{o.version})"},
    :event_url => Proc.new {|o| {:controller => 'wiki', :action => 'show', :id => o.page.title, :project_id => o.page.wiki.project, :version => o.version}},
    :activity_type => 'wiki_edits',
    :activity_permission => :view_wiki_edits,
    :activity_find_options => { :include => { :page => { :wiki => :project } } }

  def activity_type
    'wiki_edits'
  end

  def visible?(user=User.current)
    page.visible?(user)
  end

  def project
    page.project
  end

  def attachments
    page.nil? ? [] : page.attachments
  end

  # Returns the mail adresses of users that should be notified
  def recipients
    notified = project.notified_users
    notified.reject! {|user| !visible?(user)}
    notified.collect(&:mail)
  end

  # FIXME: Deprecate
  def versions
    journals
  end

  def version
    new_record? ? 0 : last_journal.version
  end

  private

  def comments_to_journal_notes
    self.init_journal(author, comments)
  end

  # FIXME: This is for backwards compatibility only. Remove once we decide it is not needed anymore
  WikiContentJournal.class_eval do
    attr_protected :data
    after_save :compress_version_text

    # Wiki Content might be large and the data should possibly be compressed
    def compress_version_text
      self.text = changes["text"].last if changes["text"]
      self.text ||= self.journaled.text
    end

    def text=(plain)
      case Setting.wiki_compression
      when "gzip"
        begin
          text_hash :text => Zlib::Deflate.deflate(plain, Zlib::BEST_COMPRESSION), :compression => Setting.wiki_compression
        rescue
          text_hash :text => plain, :compression => ''
        end
      else
        text_hash :text => plain, :compression => ''
      end
      plain
    end

    def text_hash(hash)
      changes.delete("text")
      changes["data"] = hash[:text]
      changes["compression"] = hash[:compression]
      update_attribute(:changes, changes.to_yaml)
    end

    def text
      @text ||= case changes[:compression]
      when 'gzip'
         Zlib::Inflate.inflate(data)
      else
        # uncompressed data
        changes["data"]
      end
    end

    # Returns the previous version or nil
    def previous
      @previous ||= journaled.journals.at(version - 1)
    end

    # FIXME: Deprecate
    def versioned
      journaled
    end
  end
end
