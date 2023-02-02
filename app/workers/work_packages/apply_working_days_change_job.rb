#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class WorkPackages::ApplyWorkingDaysChangeJob < ApplicationJob
  queue_with_priority :above_normal
  include ::ScheduledJob

  def perform(user_id:, previous_working_days:, previous_non_working_days:)
    user = User.find(user_id)

    User.execute_as user do
      updated_work_package_ids = collect_id_for_each(applicable_work_package(previous_working_days,
                                                                             previous_non_working_days)) do |work_package|
        apply_change_to_work_package(user, work_package)
      end
      updated_work_package_ids += collect_id_for_each(applicable_predecessor(updated_work_package_ids)) do |predecessor|
        apply_change_to_predecessor(user, predecessor)
      end

      set_journal_notice(updated_work_package_ids, previous_working_days, previous_non_working_days)
    end
  end

  private

  def apply_change_to_work_package(user, work_package)
    WorkPackages::UpdateService
      .new(user:, model: work_package, contract_class: EmptyContract)
      .call(duration: work_package.duration) # trigger a recomputation of start and due date
      .all_results
  end

  def apply_change_to_predecessor(user, predecessor)
    schedule_result = WorkPackages::SetScheduleService
                        .new(user:, work_package: predecessor)
                        .call

    # The SetScheduleService does not save. It has to be done by the caller.
    schedule_result.dependent_results.map do |dependent_result|
      work_package = dependent_result.result
      work_package.save

      work_package
    end
  end

  def applicable_work_package(previous_working_days, previous_non_working_days)
    days_of_week = changed_days(previous_working_days).keys
    dates = changed_non_working_dates(previous_non_working_days).keys
    WorkPackage
      .covering_dates_and_days_of_week(days_of_week:, dates:)
      .order(WorkPackage.arel_table[:start_date].asc.nulls_first,
             WorkPackage.arel_table[:due_date].asc)
  end

  def changed_days(previous_working_days)
    previous = Set.new(previous_working_days)
    current = Set.new(Setting.working_days)

    # `^` is a Set method returning a new set containing elements exclusive to
    # each other
    (previous ^ current).index_with { |day| current.include?(day) }
  end

  def changed_non_working_dates(previous_non_working_days)
    previous = Set.new(previous_non_working_days)
    current = Set.new(NonWorkingDay.pluck(:date))

    # `^` is a Set method returning a new set containing elements exclusive to
    # each other
    (previous ^ current).index_with { |day| current.exclude?(day) }
  end

  def applicable_predecessor(excluded)
    WorkPackage
      .where(id: Relation.follows_with_delay.select(:to_id))
      .where.not(id: excluded)
  end

  def set_journal_notice(updated_work_package_ids, previous_working_days, previous_non_working_days)
    day_changes = changed_days(previous_working_days)
    date_changes = changed_non_working_dates(previous_non_working_days)
    journal_note = journal_notice_text(day_changes, date_changes)

    WorkPackage
      .where(id: updated_work_package_ids.uniq)
      .in_batches
      .each_record do |work_package|
      work_package.journal_notes = journal_note
      work_package.save
    end
  end

  def journal_notice_text(day_changes, date_changes)
    I18n.with_locale(Setting.default_language) do
      day_changes_messages = day_changes.collect { |day, working| working_day_change_message(day, working) }
      date_changes_messages = date_changes.collect { |date, working| working_date_change_message(date, working) }
      I18n.t(:'working_days.journal_note.changed',
             changes: (day_changes_messages + date_changes_messages).join(', '))
    end
  end

  def working_day_change_message(day, working)
    I18n.t(:"working_days.journal_note.days.#{working ? :working : :non_working}",
           day: WeekDay.find_by!(day:).name)
  end

  def working_date_change_message(date, working)
    I18n.t(:"working_days.journal_note.dates.#{working ? :working : :non_working}", date:)
  end

  def collect_id_for_each(scope)
    scope.pluck(:id).map do |id|
      yield(WorkPackage.find(id)).pluck(:id)
    end.flatten
  end
end
