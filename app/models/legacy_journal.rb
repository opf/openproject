#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

require 'journal_formatter'
require 'redmine/acts/journalized/format_hooks'
require 'open_project/journal_formatter/diff'
require 'open_project/journal_formatter/attachment'
require 'open_project/journal_formatter/custom_field'

# The ActiveRecord model representing journals.
class LegacyJournal < ActiveRecord::Base
  include Comparable
  include JournalFormatter
  include JournalDeprecated
  include FormatHooks

  # Make sure each journaled model instance only has unique version ids
  validates_uniqueness_of :version, scope: [:journaled_id, :type]

  # Define a default class_name to prevent `uninitialized constant Journal::Journaled`
  # subclasses will be given an actual class name when they are created by aaj
  #
  #  e.g. IssueJournal will get class_name: 'Issue'
  belongs_to :journaled, class_name: 'Journal'
  belongs_to :user

  register_journal_formatter :diff, OpenProject::JournalFormatter::Diff
  register_journal_formatter :attachment, OpenProject::JournalFormatter::Attachment
  register_journal_formatter :custom_field, OpenProject::JournalFormatter::CustomField

  # "touch" the journaled object on creation
  after_create :touch_journaled_after_creation

  # Scopes to all journals excluding the initial journal - useful for change
  # logs like the history on issue#show
  scope :changing, -> {
    where(['version > 1'])
  }

  # let all child classes have Journal as it's model name
  # used to not having to create another route for every subclass of Journal
  def self.inherited(child)
    child.instance_eval do
      def model_name
        Journal.model_name
      end
    end
    super
  end

  def touch_journaled_after_creation
    journaled.touch
  end

  # In conjunction with the included Comparable module, allows comparison of journal records
  # based on their corresponding version numbers, creation timestamps and IDs.
  def <=>(other)
    [version, created_at, id].map(&:to_i) <=> [other.version, other.created_at, other.id].map(&:to_i)
  end

  # Returns whether the version has a version number of 1. Useful when deciding whether to ignore
  # the version during reversion, as initial versions have no serialized changes attached. Helps
  # maintain backwards compatibility.
  def initial?
    version < 2
  end

  # The anchor number for html output
  def anchor
    version - 1
  end

  # Possible shortcut to the associated project
  def project
    if journaled.respond_to?(:project)
      journaled.project
    elsif journaled.is_a? Project
      journaled
    end
  end

  def editable_by?(user)
    journaled.journal_editable_by?(user)
  end

  def details
    attributes['changed_data'] || {}
  end

  # TODO Evaluate whether this can be removed without disturbing any migrations
  alias_method :changed_data, :details

  def new_value_for(prop)
    details[prop.to_s].last if details.keys.include? prop.to_s
  end

  def old_value_for(prop)
    details[prop.to_s].first if details.keys.include? prop.to_s
  end

  # Returns a string of css classes
  def css_classes
    s = 'journal'
    s << ' has-notes' unless notes.blank?
    s << ' has-details' unless details.empty?
    s
  end

  # This is here to allow people to disregard the difference between working with a
  # Journal and the object it is attached to.
  # The lookup is as follows:
  ## => Call super if the method corresponds to one of our attributes (will end up in AR::Base)
  ## => Try the journaled object with the same method and arguments
  ## => On error, call super
  def method_missing(method, *args, &block)
    return super if respond_to?(method) || attributes[method.to_s]
    journaled.send(method, *args, &block)
  rescue NoMethodError => e
    e.name == method ? super : raise(e)
  end
end
