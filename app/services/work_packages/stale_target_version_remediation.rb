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

# One-off remediation for target versions the deleted
# WorkPackages::EnableMultipleVersionsJob reinstated from the frozen
# work_packages.version_id column. That column stopped being written once target
# versions moved to work_package_versions, so any value it still held was either
# stale (superseded or removed since) or, for work packages that never went
# through the new write path, still legitimate. This class tells the two apart
# and removes only the stale rows.
class WorkPackages::StaleTargetVersionRemediation
  CAUSE_FEATURE = "target_versions_repaired"
  CORRECTIVE_CAUSE_FEATURE = "stale_target_versions_removed"

  SUMMARY_LABELS = {
    skip_manual_change: "skipped %d (manual change since)",
    skip_no_prior_version: "skipped %d (no prior version)",
    skip_anomaly: "skipped %d (anomaly - needs human review)",
    already_corrected: "already corrected %d",
    failed: "failed %d (rolled back)"
  }.freeze

  Finding = Struct.new(:work_package, :journal, :stale_version, :action, :reason, keyword_init: true)

  # Optionally scopes the run to the given work packages or to repair journals
  # created within the given time range, for a sanity check on a few items or a
  # smaller blast radius before touching the whole dataset.
  def initialize(work_package_ids: nil, created_between: nil)
    @work_package_ids = work_package_ids.presence
    @created_between = created_between
  end

  def findings
    stale_repair_journals.filter_map { |journal| classify(journal) }
  end

  def report(out: $stdout)
    out.puts "[REPORT ONLY - DRY RUN]"
    out.puts
    print_scope(out)

    results = classified_findings(out)
    print_summary(results, out, remove_label: "would fix %d work packages")

    results
  end

  def apply(out: $stdout)
    print_scope(out)
    results = classified_findings(out)
    failures = []

    out.puts
    results.select { it.action == :remove }.each do |finding|
      remove_stale_version(finding, out:)
    rescue StandardError => e
      finding.action = :failed
      failures << [finding, e]
    end

    print_summary(results, out, remove_label: "fixed %d work packages")
    print_failures(failures, out)

    results
  end

  private

  # Findings print as they are classified so a tailed run shows progress.
  def classified_findings(out)
    stale_repair_journals.filter_map do |journal|
      classify(journal)&.tap { |finding| out.puts describe_finding(finding) }
    end
  end

  def stale_repair_journals
    scope = Journal
      .where(data_type: "Journal::WorkPackageJournal")
      .where("cause ->> 'feature' = ?", CAUSE_FEATURE)
      .order(:journable_id, :version)
    scope = scope.where(journable_id: @work_package_ids) if @work_package_ids
    scope = scope.where(created_at: @created_between) if @created_between
    scope
  end

  def print_scope(out)
    return if @work_package_ids.nil? && @created_between.nil?

    out.puts "This run is limited to:"
    out.puts "  - work packages #{@work_package_ids.join(', ')}" if @work_package_ids
    out.puts "  - repair journals created #{humanized_time_range}" if @created_between
    out.puts "Everything outside this scope is left untouched."
    out.puts
  end

  def humanized_time_range
    from = @created_between.begin&.strftime("%Y-%m-%d %H:%M %Z")
    to = @created_between.end&.strftime("%Y-%m-%d %H:%M %Z")

    if from && to
      "between #{from} and #{to}"
    elsif from
      "after #{from}"
    else
      "before #{to}"
    end
  end

  def classify(journal)
    work_package = journal.journable
    return nil if work_package.nil?

    return corrected_finding(work_package, journal) if corrected_after?(journal)

    snapshot = target_version_ids(journal)
    added = added_target_version_ids(journal, snapshot)

    return classify_no_change(work_package, journal) if added.empty?
    return classify_mismatch(work_package, journal, added) if added != Set[work_package.version_id]

    classify_candidate(work_package, journal, snapshot, added.first)
  end

  # A later journal carrying the corrective cause means this work package was
  # already fixed by a previous remediation run, even though the correction
  # itself also changed the target snapshot.
  def corrected_after?(journal)
    later_journals(journal).any? { |later| later.cause["feature"] == CORRECTIVE_CAUSE_FEATURE }
  end

  def corrected_finding(work_package, journal)
    build_finding(work_package, journal, action: :already_corrected,
                                         reason: "already corrected by a previous remediation run")
  end

  def added_target_version_ids(journal, snapshot)
    previous_snapshot = journal.previous ? target_version_ids(journal.previous) : Set.new

    snapshot - previous_snapshot
  end

  def classify_no_change(work_package, journal)
    build_finding(work_package, journal, action: :skip_anomaly,
                                         reason: "repair journal recorded no target version change")
  end

  def classify_mismatch(work_package, journal, added)
    reason = "journal delta #{format_ids(added)} does not match the frozen column value " \
             "#{work_package.version_id.inspect}"
    build_finding(work_package, journal, action: :skip_anomaly, reason:)
  end

  def classify_candidate(work_package, journal, snapshot, stale_version_id)
    if no_prior_target_version?(journal)
      return build_finding(work_package, journal, action: :skip_no_prior_version, stale_version_id:,
                                                  reason: "work package never had a target version before " \
                                                          "this journal")
    end

    if manual_change_after?(journal, snapshot)
      return build_finding(work_package, journal, action: :skip_manual_change, stale_version_id:,
                                                  reason: "target versions changed again after this journal")
    end

    current = current_target_version_ids(work_package)
    if current != snapshot
      reason = "current target set #{format_ids(current)} differs from the repair-journal snapshot " \
               "#{format_ids(snapshot)}"
      return build_finding(work_package, journal, action: :skip_anomaly, reason:)
    end

    build_finding(work_package, journal, action: :remove, stale_version_id:,
                                         reason: "reinstated by the frozen version_id column; safe to remove")
  end

  def build_finding(work_package, journal, action:, reason:, stale_version_id: nil)
    Finding.new(
      work_package:,
      journal:,
      stale_version: stale_version_id && Version.find_by(id: stale_version_id),
      action:,
      reason:
    )
  end

  def format_ids(ids) = "[#{ids.to_a.sort.join(', ')}]"

  def target_version_ids(journal)
    journal.target_version_journals.pluck(:version_id).to_set
  end

  def current_target_version_ids(work_package)
    WorkPackageVersion.where(work_package_id: work_package.id, kind: "target").pluck(:version_id).to_set
  end

  def no_prior_target_version?(journal)
    earlier_journals(journal).none? { |earlier| target_version_ids(earlier).any? }
  end

  def manual_change_after?(journal, snapshot)
    later_journals(journal).any? { |later| target_version_ids(later) != snapshot }
  end

  def earlier_journals(journal)
    journal.journable.journals.where(version: ...journal.version)
  end

  def later_journals(journal)
    journal.journable.journals.where(version: (journal.version + 1)...)
  end

  def remove_stale_version(finding, out:)
    work_package = finding.work_package

    ActiveRecord::Base.transaction do
      WorkPackageVersion
        .where(work_package_id: work_package.id, version_id: finding.stale_version.id, kind: "target")
        .delete_all

      create_corrective_journal!(work_package)
    end

    out.puts "WP##{work_package.id}: removed stale target version #{finding.stale_version.name}"
  end

  def create_corrective_journal!(work_package)
    Journal::NotificationConfiguration.with(false) do
      result = Journals::CreateService.new(work_package, User.system).call(
        cause: Journal::CausedBySystemUpdate.new(feature: CORRECTIVE_CAUSE_FEATURE)
      )
      # The journal service reports success even when no journal row was written;
      # raising rolls back the removal so it never lands without its audit journal.
      raise "corrective journal was not created" if result.result.nil?
    end
  end

  def describe_finding(finding)
    work_package = finding.work_package
    current = work_package.target_versions.map(&:name).join(", ").presence || "(none)"
    stale = finding.stale_version&.name || "(none)"

    "WP##{work_package.id}: current target versions [#{current}], " \
      "stale [#{stale}] -> #{finding.action} (#{finding.reason})"
  end

  def print_summary(results, out, remove_label:)
    grouped = results.group_by(&:action)

    out.puts
    out.puts "Summary:"
    { remove: remove_label, **SUMMARY_LABELS }.each do |action, label|
      findings = grouped.fetch(action, [])
      ids = findings.map { it.work_package.id }.join(", ")
      out.puts "  #{format(label, findings.size)}#{": #{ids}" if ids.present?}"
    end

    print_anomalies(results, out)
  end

  def print_failures(failures, out)
    return if failures.empty?

    out.puts
    out.puts "Failures (rolled back, unchanged in the database):"
    failures.each do |finding, error|
      out.puts "  WP##{finding.work_package.id}: #{error.message}"
    end
  end

  def print_anomalies(results, out)
    anomalies = results.select { it.action == :skip_anomaly }
    return if anomalies.empty?

    out.puts
    out.puts "Anomalies needing manual review:"
    anomalies.each do |finding|
      out.puts "  WP##{finding.work_package.id}: #{finding.reason}"
    end
  end
end
