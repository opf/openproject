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

# Similar to regular Journals, but under the following circumstances journals are aggregated:
#  * they are in temporal proximity
#  * they belong to the same resource
#  * they were created by the same user (i.e. the same user edited the journable)
#  * no other user has an own journal on the same object between the aggregated ones
# When a user commented (added a note) twice within a short time, the second comment will
# "open" a new aggregation, since we do not want to merge comments in any way.
# The term "aggregation" means the following when applied to our journaling:
#  * ignore/hide old journal rows (since every journal row contains a full copy of the journaled
#    object, dropping intermediate rows will just increase the diff of the following journal)
#  * in case an older row had notes, take the notes from the older row, since they shall not
#    be dropped
class Journal::AggregatedJournal
  class << self
    # Returns the aggregated journal that contains the specified (vanilla/pure) journal.
    def for_journal(pure_journal)
      raw = Journal::AggregatedJournal.query_aggregated_journals(journable: pure_journal.journable)
            .where("#{version_projection} >= ?", pure_journal.version)
            .first

      raw ? Journal::AggregatedJournal.new(raw) : nil
    end

    # Returns the aggregated journal that contains the vanilla/pure journal with the specified id.
    def with_notes_id(notes_id)
      # We need to limit the journal aggregation as soon as possible for performance reasons.
      # Therefore we have to provide the notes_id to the aggregation on top of it being used
      # in the where clause to pick the desired AggregatedJournal.
      raw_journal = query_aggregated_journals(journal_id: notes_id)
                    .where("#{table_name}.id = #{notes_id}")
                    .first

      raw_journal ? Journal::AggregatedJournal.new(raw_journal) : nil
    end

    ##
    # The +journable+ parameter allows to filter for aggregated journals of a given journable.
    #
    # The +until_version+ parameter can be used in conjunction with the +journable+ parameter
    # to see the aggregated journals as if no versions were known after the specified version.
    def aggregated_journals(journable: nil, until_version: nil, includes: [])
      raw_journals = query_aggregated_journals(journable: journable, until_version: until_version)
      predecessors = {}
      raw_journals.each do |journal|
        journable_key = [journal.journable_type, journal.journable_id]
        predecessors[journable_key] = [nil] unless predecessors[journable_key]
        predecessors[journable_key] << journal
      end

      aggregated_journals = raw_journals.map { |journal|
        journable_key = [journal.journable_type, journal.journable_id]

        Journal::AggregatedJournal.new(journal, predecessor: predecessors[journable_key].shift)
      }

      preload_associations(journable, aggregated_journals, includes)

      aggregated_journals
    end

    def query_aggregated_journals(journable: nil, until_version: nil, journal_id: nil)
      # Using the roughly aggregated groups from :sql_rough_group we need to merge journals
      # where an entry with empty notes follows an entry containing notes, so that the notes
      # from the main entry are taken, while the remaining information is taken from the
      # more recent entry. We therefore join the rough groups with itself
      # _wherever a merge would be valid_.
      # Since the results are already pre-merged, this can only happen if Our first entry (master)
      # had a comment and its successor (addition) had no comment, but can be merged.
      # This alone would, however, leave the addition in the result set, leaving a "no change"
      # journal entry back. By an additional self-join towards the predecessor, we can make sure
      # that our own row (master) would not already have been merged by its predecessor. If it is
      # (that means if we can find a valid predecessor), we drop our current row, because it will
      # already be present (in a merged form) in the row of our predecessor.
      Journal.from("(#{sql_rough_group(1, journable, until_version, journal_id)}) #{table_name}")
      .joins("LEFT OUTER JOIN (#{sql_rough_group(2, journable, until_version, journal_id)}) addition
                              ON #{sql_on_groups_belong_condition(table_name, 'addition')}")
      .joins("LEFT OUTER JOIN (#{sql_rough_group(3, journable, until_version, journal_id)}) predecessor
                         ON #{sql_on_groups_belong_condition('predecessor', table_name)}")
      .where('predecessor.id IS NULL')
      .order("COALESCE(addition.created_at, #{table_name}.created_at) ASC")
      .order("#{version_projection} ASC")
      .select("#{table_name}.journable_id,
               #{table_name}.journable_type,
               #{table_name}.user_id,
               #{table_name}.notes,
               #{table_name}.id \"notes_id\",
               #{table_name}.version \"notes_version\",
               #{table_name}.activity_type,
               COALESCE(addition.created_at, #{table_name}.created_at) \"created_at\",
               COALESCE(addition.id, #{table_name}.id) \"id\",
               #{version_projection} \"version\"")
    end

    # Returns whether "notification-hiding" should be assumed for the given journal pair.
    # This leads to an aggregated journal effectively blocking notifications of an earlier journal,
    # because it "steals" the addition from its predecessor. See the specs section under
    # "mail suppressing aggregation" (for EnqueueWorkPackageNotificationJob) for more details
    def hides_notifications?(successor, predecessor)
      return false unless successor && predecessor

      timeout = Setting.journal_aggregation_time_minutes.to_i.minutes

      if successor.journable_type != predecessor.journable_type ||
         successor.journable_id != predecessor.journable_id ||
         successor.user_id != predecessor.user_id ||
         (successor.created_at - predecessor.created_at) <= timeout
        return false
      end

      # imaginary state in which the successor never existed
      # if this makes the predecessor disappear, the successor must have taken journals
      # from it (that now became part of the predecessor again).
      !Journal::AggregatedJournal
        .query_aggregated_journals(
          journable: successor.journable,
          until_version: successor.version - 1)
        .where("#{version_projection} = #{predecessor.version}")
        .exists?
    end

    def table_name
      Journal.table_name
    end

    def version_projection
      "COALESCE(addition.version, #{table_name}.version)"
    end

    private

    # Provides a full SQL statement that returns journals that are aggregated on a basic level:
    #  * a row is dropped as soon as its successor is eligible to be merged with it
    #  * rows with a comment are never dropped (we _might_ need the comment later)
    # Thereby the result already has aggregation performed, but will still have too many rows:
    #  Changes without notes after changes containing notes (even if both were performed by
    #  the same user). Those need to be filtered out later.
    # To be able to self-join results of this statement, we add an additional column called
    # "group_number" to the result. This allows to compare a group resulting from this query with
    # its predecessor and successor.
    def sql_rough_group(uid, journable, until_version, journal_id)
      if until_version && !journable
        raise 'need to provide a journable, when specifying a version limit'
      elsif journable && journable.id.nil?
        raise 'journable has no id'
      end

      conditions = additional_conditions(journable, until_version, journal_id)

      "SELECT predecessor.*, #{sql_group_counter(uid)} AS group_number
      FROM #{sql_rough_group_from_clause(uid)}
      #{sql_rough_group_join(conditions[:join_conditions])}
      #{sql_rough_group_where(conditions[:where_conditions])}"
    end

    def additional_conditions(journable, until_version, journal_id)
      where_conditions = ''
      join_conditions = ''

      if journable
        where_conditions += " AND predecessor.journable_type = '#{journable.class.name}' AND
                                  predecessor.journable_id = #{journable.id}"

        if until_version
          where_conditions += " AND predecessor.version <= #{until_version}"
          join_conditions += "AND successor.version <= #{until_version}"
        end
      end

      if journal_id
        where_conditions += "AND predecessor.id IN (
                SELECT id_key.id
                FROM #{table_name} id_key JOIN #{table_name} journable_key
                  ON id_key.journable_id = journable_key.journable_id
                  AND id_key.journable_type = journable_key.journable_type
                  AND journable_key.id = #{journal_id})"
      end

      { where_conditions: where_conditions,
        join_conditions: join_conditions }
    end

    def sql_rough_group_join(additional_conditions)
      "LEFT OUTER JOIN #{table_name} successor
        ON predecessor.version + 1 = successor.version AND
           predecessor.journable_type = successor.journable_type AND
           predecessor.journable_id = successor.journable_id
           #{additional_conditions}"
    end

    def sql_rough_group_where(additional_conditions)
      "WHERE (predecessor.user_id != successor.user_id OR
             (predecessor.notes != '' AND predecessor.notes IS NOT NULL) OR
             #{sql_beyond_aggregation_time?('predecessor', 'successor')} OR
             successor.id IS NULL)
             #{additional_conditions}"
    end

    # The "group_number" required in :sql_rough_group has to be generated differently depending on
    # the DBMS used. This method returns the appropriate statement to be used inside a SELECT to
    # obtain the current group number.
    # The :uid parameter allows to define non-conflicting variable names (for MySQL).
    def sql_group_counter(uid)
      if OpenProject::Database.mysql?
        group_counter = mysql_group_count_variable(uid)
        "(#{group_counter} := #{group_counter} + 1)"
      else
        'row_number() OVER (ORDER BY predecessor.version ASC)'
      end
    end

    # MySQL requires some initialization to be performed before being able to count the groups.
    # This method allows to inject further FROM sources to achieve that in a single SQL statement.
    # Sadly MySQL requires the whole statement to be wrapped in parenthesis, while PostgreSQL
    # prohibits that.
    def sql_rough_group_from_clause(uid)
      if OpenProject::Database.mysql?
        "(journals predecessor, (SELECT #{mysql_group_count_variable(uid)}:=0) number_initializer)"
      else
        'journals predecessor'
      end
    end

    def mysql_group_count_variable(uid)
      "@aggregated_journal_row_counter_#{uid}"
    end

    # Similar to the WHERE statement used in :sql_rough_group. However, this condition will
    # match (return true) for all pairs where a merge/aggregation IS possible.
    def sql_on_groups_belong_condition(predecessor, successor)
      "#{predecessor}.group_number + 1 = #{successor}.group_number AND
      (NOT #{sql_beyond_aggregation_time?(predecessor, successor)} AND
      #{predecessor}.user_id = #{successor}.user_id AND
      #{successor}.journable_type = #{predecessor}.journable_type AND
      #{successor}.journable_id = #{predecessor}.journable_id AND
      NOT ((#{predecessor}.notes != '' AND #{predecessor}.notes IS NOT NULL) AND
      (#{successor}.notes != '' AND #{successor}.notes IS NOT NULL)))"
    end

    # Returns a SQL condition that will determine whether two entries are too far apart (temporal)
    # to be considered for aggregation. This takes the current instance settings for temporal
    # proximity into account.
    def sql_beyond_aggregation_time?(predecessor, successor)
      aggregation_time_seconds = Setting.journal_aggregation_time_minutes.to_i.minutes
      if aggregation_time_seconds == 0
        # if aggregation is disabled, we consider everything to be beyond aggregation time
        # even if creation dates are exactly equal
        return '(true = true)'
      end

      if OpenProject::Database.mysql?
        difference = "TIMESTAMPDIFF(second, #{predecessor}.created_at, #{successor}.created_at)"
        threshold = aggregation_time_seconds
      else
        difference = "(#{successor}.created_at - #{predecessor}.created_at)"
        threshold = "interval '#{aggregation_time_seconds} second'"
      end

      "(#{difference} > #{threshold})"
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

      aggregated_journals.each { |journal|
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
      }
    end
  end

  include JournalChanges
  include JournalFormatter
  include Redmine::Acts::Journalized::FormatHooks

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
           :data,
           :data=,
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
    self.class.with_notes_id(notes_id)
  end

  def user
    @user ||= User.find(user_id)
  end

  def predecessor
    unless defined? @predecessor
      raw_journal = self.class.query_aggregated_journals(journable: journable)
                    .where("#{self.class.version_projection} < ?", version)
                    .except(:order)
                    .order("#{self.class.version_projection} DESC")
                    .first

      @predecessor = raw_journal ? Journal::AggregatedJournal.new(raw_journal) : nil
    end

    @predecessor
  end

  def successor
    unless defined? @successor
      raw_journal = self.class.query_aggregated_journals(journable: journable)
                      .where("#{self.class.version_projection} > ?", version)
                      .except(:order)
                      .order("#{self.class.version_projection} ASC")
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

  private

  attr_reader :journal
end
