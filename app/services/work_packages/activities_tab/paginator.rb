# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

# Paginates work package activities (journals and changesets) with support for
# filtering and anchor navigation.
#
# Filter modes:
# - :all - Shows all activities (default)
# - :only_comments - Shows only journals with notes
# - :only_changes - Shows only journals with detected changes using SQL heuristics
#
# Anchor format:
# - "comment-{journal_id}" - Navigate to a specific journal by id
# - "activity-{sequence_version}" - Legacy alias resolved on demand to the
#   journal's comment id; the sequence version is computed only for this lookup,
#   never for the rendered page, so the default feed avoids the window function.
#
# Anchored navigation bypasses the active filter so a deep link to a record
# that wouldn't match the filter still resolves.
#
# Internally, the activities feed is a single Journal relation paginated by
# pagy at the database level. Only the page slice is materialised — eager-loaded
# and wrapped — keeping per-request cost independent of total history size.
#
# @param work_package [WorkPackage] The work package to paginate activities for
# @param params [Hash] Pagination and filtering parameters
#
# @option params [Integer] :page Page number (default: 1)
# @option params [Integer] :limit Records per page (default: Pagy::DEFAULT[:limit])
# @option params [Symbol] :filter Filter mode (:all, :only_comments, :only_changes)
# @option params [String] :anchor Anchor to navigate to specific journal
#
# @return [(Pagy, Array)] Pagy pagination object and array of activity records
class WorkPackages::ActivitiesTab::Paginator
  include Pagy::Method
  include WorkPackages::ActivitiesTab::JournalSortingInquirable

  Filters = WorkPackages::ActivitiesTab::Filters

  attr_reader :work_package, :params, :filter, :resolved_anchor

  def initialize(work_package, params = {})
    @work_package = work_package
    @params = params
    @filter = Filters.cast(params[:filter])
    @resolved_anchor = nil
  end

  def call
    anchor_type, target_record_id = parse_anchor

    pagy_obj, page_relation =
      if anchor_type && target_record_id
        pagy_at_anchor(anchor_type, target_record_id)
      else
        pagy(:offset, activities_scope, **pagy_options)
      end

    activities = load_activities(page_relation)
    # For UI display: if user wants "oldest first" UI, reverse the collection
    activities = activities.reverse if journal_sorting.asc?

    [pagy_obj, activities]
  end

  private

  def parse_anchor
    anchor = params[:anchor] # e.g., "comment-78758" (without #)
    return unless anchor

    match = anchor.match(/^(comment|activity)-(\d+)$/)
    return unless match

    [match[1].inquiry, match[2].to_i]
  end

  # An unresolvable anchor falls back to page 1; any params[:page] sent
  # alongside is ignored, since the anchor is the explicit navigation intent.
  def pagy_at_anchor(anchor_type, target_record_id)
    scope = activities_scope(filter: Filters::ALL)
    page = page_for_anchor(scope, anchor_type, target_record_id) || 1
    pagy(:offset, scope, **pagy_options, page:)
  end

  # The activity feed as a single Journal relation, newest-first: the work
  # package's journals plus the journals written for its changesets — changesets
  # are journalized, so each carries a journal timestamped with its committed_on.
  def activities_scope(filter: self.filter)
    scope = filtered_journals(filter)
    scope = scope.or(changeset_journals) if include_changesets?(filter)
    scope.reorder(created_at: :desc, id: :desc)
  end

  def pagy_options
    {
      page: params[:page] || 1,
      limit:,
      request: { params: }
    }.compact
  end

  # Coerced to a positive integer to match how pagy reads the same option:
  # a non-positive value floors to one page, avoiding a ZeroDivisionError.
  def limit
    (params[:limit] || Pagy::DEFAULT[:limit]).to_i.clamp(1..)
  end

  # Eager-loads are applied to the page slice here, not to activities_scope, so
  # the count query stays off them. Changeset journals map back to Changeset
  # records; work package journals go through the wrapper.
  def load_activities(page_relation)
    journals = page_journals(page_relation)
    changesets = load_changesets(journals.select { changeset?(it) }.map(&:journable_id))
    wrapped = wrap_journals(journals.reject { changeset?(it) })

    journals.filter_map { |journal| changeset?(journal) ? changesets[journal.journable_id] : wrapped[journal.id] }
  end

  def page_for_anchor(scope, anchor_type, target_record_id)
    activity_at, anchor_id = locate_anchor(anchor_type, target_record_id)
    return nil unless activity_at && anchor_id

    record_resolved_anchor(anchor_type, anchor_id)

    rows_ahead = scope
      .where("(journals.created_at, journals.id) > (?, ?)", activity_at, anchor_id)
      .count(:all)

    (rows_ahead / limit) + 1
  end

  def filtered_journals(filter)
    case filter
    when Filters::ONLY_COMMENTS then apply_comments_only_filter(visible_journals)
    when Filters::ONLY_CHANGES then apply_changes_only_filter(visible_journals)
    else visible_journals
    end
  end

  def changeset_journals
    Journal.where(journable_type: Changeset.name,
                  journable_id: work_package.changesets.except(:order).select(:id))
  end

  # Most work packages have no changesets (revisions are a legacy feature), so
  # the changeset leg is merged in only when one exists — keeping the common
  # query scoped to the work package's own journals.
  def include_changesets?(filter)
    filter != Filters::ONLY_COMMENTS && work_package.changesets.exists?
  end

  def page_journals(page_relation)
    page_relation
      .includes(:user, :customizable_journals, :attachable_journals, :storable_journals, :notifications, :attachments)
      .to_a
  end

  def load_changesets(ids)
    return {} if ids.empty?

    Changeset
      .where(id: ids)
      .includes(:user, :repository, :project)
      .index_by(&:id)
  end

  def wrap_journals(journals)
    API::V3::Activities::ActivityEagerLoadingWrapper.wrap(journals).index_by(&:id)
  end

  def changeset?(journal)
    journal.journable_type == Changeset.name
  end

  def locate_anchor(anchor_type, target_record_id)
    if anchor_type.comment?
      visible_journals.where(id: target_record_id).pick(:created_at, :id)
    elsif anchor_type.activity?
      locate_anchor_by_sequence_version(target_record_id)
    end
  end

  # A comment anchor already matches the DOM's data-anchor-comment-id. An activity
  # anchor has no rendered counterpart, so hand the comment id it resolved to back
  # to the client to scroll to instead.
  def record_resolved_anchor(anchor_type, anchor_id)
    @resolved_anchor = anchor_id if anchor_type.activity?
  end

  def apply_comments_only_filter(scope)
    scope.where.not(notes: [nil, ""])
  end

  def apply_changes_only_filter(scope)
    JournalChangesFilter.apply(scope)
  end

  def visible_journals
    work_package.journals.internal_visible
  end

  def locate_anchor_by_sequence_version(sequence_version)
    visible_journals
      .with_sequence_version
      .where(ranked: { sequence_version: sequence_version })
      .pick(:created_at, :id)
  end
end
