#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'zlib'

class WikiContent < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :page, class_name: 'WikiPage', foreign_key: 'page_id'
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  validates_presence_of :text
  validates_length_of :comments, maximum: 255, allow_nil: true

  attr_accessor :comments

  # attr_protected :author_id

  before_save :comments_to_journal_notes

  acts_as_journalized

  acts_as_event type: 'wiki-page',
                title: Proc.new { |o| "#{l(:label_wiki_edit)}: #{o.journal.journable.page.title} (##{o.journal.journable.version})" },
                url: Proc.new { |o| { controller: '/wiki', action: 'show', id: o.journal.journable.page, project_id: o.journal.journable.page.wiki.project, version: o.journal.journable.version } }

  def activity_type
    'wiki_edits'
  end

  def visible?(user = User.current)
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
    notified.reject! { |user| !visible?(user) }
    notified.map(&:mail)
  end

  # FIXME: Deprecate
  def versions
    journals
  end

  # REVIEW
  def version
    last_journal.nil? ? 0 : last_journal.version
  end

  private

  def comments_to_journal_notes
    add_journal author, comments
  end

  # FIXME: This is for backwards compatibility only. Remove once we decide it is not needed anymore
  #  WikiContentJournal.class_eval do
  #    attr_protected :data
  #    after_save :compress_version_text
  #
  #    # Wiki Content might be large and the data should possibly be compressed
  #    def compress_version_text
  #      self.text = changed_data["text"].last if changed_data["text"]
  #      self.text ||= self.journaled.text
  #    end
  #
  #    def text=(plain)
  #      case Setting.wiki_compression
  #      when "gzip"
  #        begin
  #          text_hash :text => Zlib::Deflate.deflate(plain, Zlib::BEST_COMPRESSION), :compression => Setting.wiki_compression
  #        rescue
  #          text_hash :text => plain, :compression => ''
  #        end
  #      else
  #        text_hash :text => plain, :compression => ''
  #      end
  #      plain
  #    end
  #
  #    def text_hash(hash)
  #      changed_data.delete("text")
  #      changed_data["data"] = hash[:text]
  #      changed_data["compression"] = hash[:compression]
  #      update_attribute(:changed_data, changed_data)
  #    end
  #
  #    def text
  #      @text ||= case changed_data["compression"]
  #      when "gzip"
  #         Zlib::Inflate.inflate(changed_data["data"])
  #      else
  #        # uncompressed data
  #        changed_data["data"]
  #      end
  #    end
  #
  #    # Returns the previous version or nil
  #    def previous
  #      @previous ||= journaled.journals.at(version - 1)
  #    end
  #
  #    # FIXME: Deprecate
  #    def versioned
  #      journaled
  #    end
  #  end
end
