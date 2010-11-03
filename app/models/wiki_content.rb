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

require 'zlib'

class WikiContent < ActiveRecord::Base
  belongs_to :page, :class_name => 'WikiPage', :foreign_key => 'page_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  validates_presence_of :text
  validates_length_of :comments, :maximum => 255, :allow_nil => true

  acts_as_journalized :event_type => 'wiki-page',
    :event_title => Proc.new {|o| "#{l(:label_wiki_edit)}: #{o.page.title} (##{o.version})"},
    :event_url => Proc.new {|o| {:controller => 'wiki', :id => o.page.wiki.project_id, :page => o.page.title, :version => o.version}},
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
    unless last_journal
      # FIXME: This is code that caters for a case that should never happen in the normal code paths!!
      create_journal
      last_journal.update_attribute(:created_at, updated_on)
    end
    last_journal.version
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
