#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# Similar to regular Journals, but under the following circumstances a set of individual journals is aggregated to
# a single logical journal:
#  * they are in temporal proximity
#  * they belong to the same resource
#  * they were created by the same user (i.e. the same user edited the journable)
#  * no other user has an own journal on the same object between the aggregated ones
# When a user commented (added a note) twice within a short time, the first comment will
# finish the aggregation, since we do not want to merge comments in any way.
# The term "aggregation" means the following when applied to our journaling:
#  * ignore/hide old journal rows (since every journal row contains a full copy of the journaled
#    object, dropping intermediate rows will just increase the diff of the following journal)
#  * in case an older row had notes, take the notes from the older row, since they shall not
#    be dropped
class Journal::AggregatedJournal
  class << self
    def with_version(pure_journal)
      wp_journals = aggregated_journals(journable: pure_journal.journable)
      wp_journals.detect { |journal| journal.version == pure_journal.version }
    end

    # Returns the aggregated journal that contains the specified (vanilla/pure) journal.
    def containing_journal(pure_journal)
      raw = Journal::Scopes::AggregatedJournal.fetch(journable: pure_journal.journable)
            .where("version >= ?", pure_journal.version)
            .first

      raw ? Journal::AggregatedJournal.new(raw) : nil
    end

    ##
    # The +journable+ parameter allows to filter for aggregated journals of a given journable.
    #
    # The +until_version+ parameter can be used in conjunction with the +journable+ parameter
    # to see the aggregated journals as if no versions were known after the specified version.
    def aggregated_journals(journable: nil, sql: nil, until_version: nil, includes: [])
      raw_journals = Journal::Scopes::AggregatedJournal.fetch(journable: journable, sql: sql, until_version: until_version)

      aggregated_journals = map_to_aggregated_journals(raw_journals)
      preload_associations(journable, aggregated_journals, includes)

      aggregated_journals
    end

    # Returns whether "notification-hiding" should be assumed for the given journal pair.
    # This leads to an aggregated journal effectively blocking notifications of an earlier journal,
    # because it "steals" the addition from its predecessor. See the specs section under
    # "mail suppressing aggregation" (for EnqueueWorkPackageNotificationJob) for more details
    def hides_notifications?(successor, predecessor)
      return false unless successor && predecessor
      return false if belong_to_different_groups?(predecessor, successor)

      # imaginary state in which the successor never existed
      # if this makes the predecessor disappear, the successor must have taken journals
      # from it (that now became part of the predecessor again).
      !Journal::Scopes::AggregatedJournal
        .fetch(
          journable: successor.journable,
          until_version: successor.version - 1
        )
        .where(version: predecessor.version)
        .exists?
    end

    private

    def map_to_aggregated_journals(raw_journals)
      predecessors = {}
      raw_journals.each do |journal|
        journable_key = [journal.journable_type, journal.journable_id]
        predecessors[journable_key] = [nil] unless predecessors[journable_key]
        predecessors[journable_key] << journal
      end

      raw_journals.map do |journal|
        journable_key = [journal.journable_type, journal.journable_id]

        Journal::AggregatedJournal.new(journal, predecessor: predecessors[journable_key].shift)
      end
    end

    def preload_associations(journable, aggregated_journals, includes)
      return unless includes.length > 1

      journal_ids = aggregated_journals.map(&:id)

      customizable_journals = if includes.include?(:customizable_journals)
                                Journal::CustomizableJournal
                                .where(journal_id: journal_ids)
                                .all
                                .group_by(&:journal_id)
                              end

      attachable_journals = if includes.include?(:customizable_journals)
                              Journal::AttachableJournal
                              .where(journal_id: journal_ids)
                              .all
                              .group_by(&:journal_id)
                            end

      data = if includes.include?(:data)
               "Journal::#{journable.class}Journal".constantize
               .where(journal_id: journal_ids)
               .all
               .group_by(&:journal_id)
             end

      aggregated_journals.each do |journal|
        if includes.include?(:customizable_journals)
          journal.set_preloaded_customizable_journals customizable_journals[journal.id]
        end
        if includes.include?(:attachable_journals)
          journal.set_preloaded_attachable_journals attachable_journals[journal.id]
        end
        if includes.include?(:data)
          journal.set_preloaded_data data[journal.id].first
        end
        if journable
          journal.set_preloaded_journable journable
        end
      end
    end

    def belong_to_different_groups?(predecessor, successor)
      timeout = Setting.journal_aggregation_time_minutes.to_i.minutes

      successor.journable_type != predecessor.journable_type ||
        successor.journable_id != predecessor.journable_id ||
        successor.user_id != predecessor.user_id ||
        (successor.created_at - predecessor.created_at) <= timeout
    end
  end

  include JournalChanges
  include JournalFormatter
  include ::Acts::Journalized::FormatHooks

  register_journal_formatter :diff, OpenProject::JournalFormatter::Diff
  register_journal_formatter :attachment, OpenProject::JournalFormatter::Attachment
  register_journal_formatter :custom_field, OpenProject::JournalFormatter::CustomField

  alias_method :details, :get_changes

  delegate :journable_type,
           :journable_id,
           :journable,
           :journable=,
           :user_id,
           :user,
           :notes,
           :notes?,
           :activity_type,
           :created_at,
           :id,
           :version,
           :attributes,
           :attachable_journals,
           :attachable_journals=,
           :customizable_journals,
           :customizable_journals=,
           :editable_by?,
           :notes_id,
           :notes_version,
           :project,
           :data,
           to: :journal

  # Initializes a new AggregatedJournal. Allows to explicitly set a predecessor, if it is already
  # known. Providing a predecessor is only to improve efficiency, it is not required.
  # In case the predecessor is not known, it will be lazily retrieved.
  def initialize(journal, predecessor: false)
    @journal = journal

    # explicitly checking false to allow passing nil as "no predecessor"
    # mind that we check @predecessor with defined? below, so don't assign to it in all cases!
    unless predecessor == false
      @predecessor = predecessor
    end
  end

  # returns an instance of this class that is reloaded from the database
  def reloaded
    self.class.containing_journal(journal)
  end

  def user
    @user ||= User.find(user_id)
  end

  def data=(data)
    @data = data
  end

  def predecessor
    unless defined? @predecessor
      raw_journal = Journal::Scopes::AggregatedJournal.fetch(journable: journable)
                    .where("version < ?", version)
                    .except(:order)
                    .order(version: :desc)
                    .first

      @predecessor = raw_journal ? Journal::AggregatedJournal.new(raw_journal) : nil
    end

    @predecessor
  end

  def successor
    unless defined? @successor
      raw_journal = Journal::Scopes::AggregatedJournal.fetch(journable: journable)
                      .where("version > ?", version)
                      .except(:order)
                      .order(version: :asc)
                      .first

      @successor = raw_journal ? Journal::AggregatedJournal.new(raw_journal) : nil
    end

    @successor
  end

  def set_preloaded_customizable_journals(loaded_journals)
    self.customizable_journals = loaded_journals if loaded_journals
    customizable_journals.proxy_association.loaded!
  end

  def set_preloaded_attachable_journals(loaded_journals)
    self.attachable_journals = loaded_journals if loaded_journals
    attachable_journals.proxy_association.loaded!
  end

  def set_preloaded_data(loaded_data)
    self.data = loaded_data
  end

  def set_preloaded_journable(loaded_journable)
    self.journable = loaded_journable
    journal.association(:journable).loaded!
  end

  def initial?
    predecessor.nil?
  end

  # If we where to delegate here, the wrapped journal would be compared to its predecessor which is
  # not necessarily the this aggreated journal's predecessor.
  def noop?
    (!notes || notes&.empty?) && get_changes.empty?
  end

  private

  attr_reader :journal
end
