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

require "spec_helper"

RSpec.describe Backlogs::WorkPackages::BatchUpdateService,
               "concurrent destination updates",
               type: :model,
               use_transactional_fixtures: false do
  self.use_transactional_tests = false

  before do
    baseline_user_ids
    baseline_role_ids
    baseline_status_ids
    baseline_priority_ids
    fixture_connection_pool.unpin_connection!
  end

  after do
    side_user_ids = factory_side_user_ids
    project.destroy!
    user.destroy!
    User.where(id: side_user_ids).destroy_all
    TypeVariant.where(type_id: type.id).delete_all
    Type.unscoped.where(id: type.id).delete_all
    Role.where.not(id: baseline_role_ids).destroy_all
    Status.where.not(id: baseline_status_ids).delete_all
    IssuePriority.where.not(id: baseline_priority_ids).delete_all
  ensure
    fixture_connection_pool.pin_connection!(true)
  end

  let(:fixture_connection_pool) { ActiveRecord::Base.connection_pool }
  let(:baseline_user_ids) { User.not_builtin.ids }
  let(:factory_side_user_ids) do
    User.not_builtin.where.not(id: [*baseline_user_ids, user.id]).ids
  end
  let(:baseline_role_ids) { Role.pluck(:id) }
  let(:baseline_status_ids) { Status.pluck(:id) }
  let(:baseline_priority_ids) { IssuePriority.pluck(:id) }
  let!(:type) { create(:type) }
  let!(:project) do
    create(:project, types: [type], enabled_module_names: %i[backlogs work_package_tracking])
  end
  let!(:user) do
    create(:user, member_with_permissions: {
             project => %i[
               view_work_packages
               edit_work_packages
               view_sprints
               manage_sprint_items
               start_complete_sprint
             ]
           })
  end
  let!(:source_sprint) do
    create(:sprint,
           project:,
           status: :active,
           start_date: Date.current,
           finish_date: 1.week.from_now.to_date)
  end
  let!(:source_bucket) { create(:backlog_bucket, project:) }
  let!(:empty_bucket) { create(:backlog_bucket, project:) }
  let!(:sprint_work_packages) do
    create_list(:work_package, 2, sprint: source_sprint, type:, project:)
  end
  let!(:bucket_work_packages) do
    create_list(:work_package, 2, backlog_bucket: source_bucket, type:, project:)
  end

  def cleanup_concurrency_threads(release_events:, threads:, join_timeout: 5)
    original_exception = $!
    release_events.compact.each(&:set)
    threads = threads.compact
    cleanup_errors = []

    threads.each do |thread|
      collect_cleanup_error(cleanup_errors) { thread.join(join_timeout) }
    end

    lingering_threads = threads.select(&:alive?)
    if lingering_threads.any?
      cleanup_errors << RuntimeError.new(
        "#{lingering_threads.size} thread(s) did not stop during concurrency cleanup"
      )
    end

    lingering_threads.each do |thread|
      collect_cleanup_error(cleanup_errors) { thread.kill }
      collect_cleanup_error(cleanup_errors) { thread.join }
    end

    return if original_exception || cleanup_errors.empty?

    raise cleanup_errors.first
  end

  def collect_cleanup_error(cleanup_errors)
    yield
  rescue StandardError => e
    cleanup_errors << e
  end

  # rubocop:disable RSpec/ExampleLength
  it "serializes disjoint batches before resolving append placement in an empty target", retry: 0 do
    first_service = described_class.new(user:, work_packages: sprint_work_packages)
    second_service = described_class.new(user:, work_packages: bucket_work_packages)
    first_paused = Concurrent::Event.new
    release_first = Concurrent::Event.new
    second_progress = Queue.new

    allow(first_service).to receive(:target_available?).and_wrap_original do |method, *args|
      first_paused.set
      raise "timed out waiting to release the first append" unless release_first.wait(5)

      method.call(*args)
    end
    allow(second_service).to receive(:resolve_placement).and_wrap_original do |method, *args|
      resolved = method.call(*args)
      second_progress << :placement_resolved
      resolved
    end
    allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction)
      .and_wrap_original do |method, entry, suffix = nil, *args, &block|
        if Thread.current[:batch_append] == :second && entry == empty_bucket && suffix.nil?
          second_progress << :destination_lifecycle_lock_attempted
        end
        method.call(entry, suffix, *args, &block)
      end

    first_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Thread.current[:batch_append] = :first
        first_service.call(list_type: "backlog_bucket", list_id: empty_bucket.id.to_s)
      end
    end
    raise "first append did not reach the placement barrier" unless first_paused.wait(5)

    second_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Thread.current[:batch_append] = :second
        second_service.call(list_type: "backlog_bucket", list_id: empty_bucket.id.to_s)
      end
    end

    observed_progress = Timeout.timeout(5) { second_progress.pop }
    release_first.set
    first_result = first_thread.value
    second_result = second_thread.value

    expect(observed_progress).to eq :destination_lifecycle_lock_attempted
    expect([first_result, second_result]).to all(be_success)
    expect(WorkPackage.where(backlog_bucket: empty_bucket).order(:position).pluck(:id))
      .to eq [*sprint_work_packages.map(&:id), *bucket_work_packages.map(&:id)]
  ensure
    cleanup_concurrency_threads(
      release_events: [release_first],
      threads: [first_thread, second_thread]
    )
  end
  # rubocop:enable RSpec/ExampleLength

  # rubocop:disable RSpec/ExampleLength
  it "serializes whitespace-top moves before placing into an empty inbox", retry: 0 do
    first_service = described_class.new(user:, work_packages: sprint_work_packages)
    second_service = described_class.new(user:, work_packages: bucket_work_packages)
    first_placed = Concurrent::Event.new
    release_first = Concurrent::Event.new
    release_second = Concurrent::Event.new
    second_progress = Queue.new

    allow(first_service).to receive(:move_members).and_wrap_original do |method, *args, **kwargs, &block|
      result = method.call(*args, **kwargs, &block)
      first_placed.set
      raise "timed out waiting to commit the first top move" unless release_first.wait(5)

      result
    end
    allow(second_service).to receive(:move_members).and_wrap_original do |method, *args, **kwargs, &block|
      result = method.call(*args, **kwargs, &block)
      second_progress << :placement_finished
      raise "timed out waiting to commit the second top move" unless release_second.wait(5)

      result
    end
    allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction)
      .and_wrap_original do |method, entry, suffix = nil, *args, &block|
        if Thread.current[:batch_top] == :second &&
           entry == project && suffix == "backlogs_batch_update_destination_inbox"
          second_progress << :target_lock_attempted
        end
        method.call(entry, suffix, *args, &block)
      end

    first_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Thread.current[:batch_top] = :first
        first_service.call(list_type: "inbox", prev_id: " \t")
      end
    end
    raise "first top move did not reach the commit barrier" unless first_placed.wait(5)

    second_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Thread.current[:batch_top] = :second
        second_service.call(list_type: "inbox", prev_id: " \t")
      end
    end

    observed_progress = Timeout.timeout(5) { second_progress.pop }
    release_first.set
    release_second.set
    first_result = first_thread.value
    second_result = second_thread.value

    expect([first_result, second_result]).to all(be_success)
    inbox_work_packages = WorkPackage.where(project:, sprint_id: nil, backlog_bucket_id: nil)
    expect(inbox_work_packages.order(:position).pluck(:position)).to eq [1, 2, 3, 4]
    expect(inbox_work_packages.order(:position).pluck(:id))
      .to eq [*bucket_work_packages.map(&:id), *sprint_work_packages.map(&:id)]
    expect(observed_progress).to eq :target_lock_attempted
  ensure
    cleanup_concurrency_threads(
      release_events: [release_first, release_second],
      threads: [first_thread, second_thread]
    )
  end
  # rubocop:enable RSpec/ExampleLength

  # rubocop:disable RSpec/ExampleLength
  it "waits for a destination mutation before checking a same-list move", retry: 0 do
    release_mutation = Concurrent::Event.new
    mutation_ready = Concurrent::Event.new
    mutation_pid = Queue.new
    batch_pid = Queue.new
    batch_result = Queue.new
    batch_finished = Concurrent::Event.new
    original_order = sprint_work_packages.map(&:id)

    mutation_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        Sprint.transaction do
          locked_sprint = Sprint.lock.find(source_sprint.id)
          locked_sprint.update!(status: :completed)
          mutation_pid << connection.select_value("SELECT pg_backend_pid()").to_i
          mutation_ready.set
          raise "timed out waiting to commit the sprint mutation" unless release_mutation.wait(5)
        end
      end
    end
    raise "sprint mutation did not acquire its row lock" unless mutation_ready.wait(5)

    batch_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        batch_pid << connection.select_value("SELECT pg_backend_pid()").to_i
        result = described_class
          .new(user:, work_packages: [sprint_work_packages.last])
          .call(list_type: "sprint", list_id: source_sprint.id.to_s, prev_id: "")
        batch_result << result
        batch_finished.set
      end
    end

    mutator_backend_pid = Timeout.timeout(5) { mutation_pid.pop }
    batch_backend_pid = Timeout.timeout(5) { batch_pid.pop }
    observed_progress = Timeout.timeout(5) do
      loop do
        blocked = ActiveRecord::Base.connection.select_value(
          "SELECT #{mutator_backend_pid} = ANY(pg_blocking_pids(#{batch_backend_pid}))"
        )
        break :destination_lock_wait if blocked
        break :batch_finished if batch_finished.set?

        batch_finished.wait(0.01)
      end
    end

    release_mutation.set
    mutation_thread.value
    batch_thread.value
    result = Timeout.timeout(5) { batch_result.pop }

    expect(observed_progress).to eq :destination_lock_wait
    expect(result).to be_failure
    expect(result.message)
      .to eq I18n.t("backlogs.work_packages.batch_update_service.unavailable_target")
    expect(source_sprint.reload).to be_completed
    expect(source_sprint.work_packages_for(project).pluck(:id)).to eq original_order
  ensure
    cleanup_concurrency_threads(
      release_events: [release_mutation],
      threads: [mutation_thread, batch_thread]
    )
  end
  # rubocop:enable RSpec/ExampleLength

  # rubocop:disable RSpec/ExampleLength
  it "waits for sprint finish before resolving an append", retry: 0 do
    finish_paused = Concurrent::Event.new
    release_finish = Concurrent::Event.new
    batch_progress = Queue.new
    batch_result = Queue.new
    append_work_package = bucket_work_packages.first
    original_cohort = sprint_work_packages.map(&:id)
    append_service = described_class.new(user:, work_packages: [append_work_package])

    allow(WorkPackages::UpdateService).to receive(:new).and_wrap_original do |method, *args, **kwargs|
      if Thread.current[:finish_race] && !Thread.current[:finish_paused]
        Thread.current[:finish_paused] = true
        finish_paused.set
        raise "timed out waiting to continue sprint finish" unless release_finish.wait(5)
      end

      method.call(*args, **kwargs)
    end
    allow(append_service).to receive(:resolve_placement).and_wrap_original do |method, *args|
      resolved = method.call(*args)
      batch_progress << :placement_resolved
      resolved
    end
    allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction)
      .and_wrap_original do |method, entry, *args, &block|
        if Thread.current[:finish_race_batch] && entry.is_a?(Sprint) && entry.id == source_sprint.id
          batch_progress << :sprint_lock_attempted
        end
        method.call(entry, *args, &block)
      end

    finish_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Thread.current[:finish_race] = true
        Backlogs::Sprints::FinishService
          .new(user:, model: source_sprint)
          .call(unfinished_action: "move_to_top_of_backlog")
      end
    end
    raise "sprint finish did not reach its first work-package update" unless finish_paused.wait(5)

    batch_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Thread.current[:finish_race_batch] = true
        result = append_service.call(list_type: "sprint", list_id: source_sprint.id.to_s)
        batch_result << result
      end
    end

    observed_progress = Timeout.timeout(5) { batch_progress.pop }

    expect(observed_progress).to eq :sprint_lock_attempted
    expect(batch_thread.join(0.1)).to be_nil
    expect(batch_progress).to be_empty

    release_finish.set
    finish_result = finish_thread.value
    batch_thread.value
    append_result = Timeout.timeout(5) { batch_result.pop }

    expect(finish_result).to be_success
    expect(append_result).to be_failure
    expect(append_result.message)
      .to eq I18n.t("backlogs.work_packages.batch_update_service.unavailable_target")
    expect(source_sprint.reload).to be_completed
    expect(WorkPackage.where(id: original_cohort).pluck(:sprint_id)).to all(be_nil)
    expect(source_sprint.work_packages_for(project)).to be_empty
    expect(append_work_package.reload).to have_attributes(backlog_bucket: source_bucket, sprint_id: nil)
  ensure
    cleanup_concurrency_threads(
      release_events: [release_finish],
      threads: [finish_thread, batch_thread]
    )
  end
  # rubocop:enable RSpec/ExampleLength

  # rubocop:disable RSpec/ExampleLength
  it "waits for sprint finish before moving its enumerated cohort out", retry: 0 do
    finish_paused = Concurrent::Event.new
    release_finish = Concurrent::Event.new
    batch_progress = Queue.new
    batch_result = Queue.new
    moving_work_package = sprint_work_packages.last
    original_cohort = sprint_work_packages.map(&:id)
    move_service = described_class.new(user:, work_packages: [moving_work_package])

    allow(WorkPackages::UpdateService).to receive(:new).and_wrap_original do |method, *args, **kwargs|
      if Thread.current[:finish_move_out_race] && !Thread.current[:finish_paused]
        Thread.current[:finish_paused] = true
        finish_paused.set
        raise "timed out waiting to continue sprint finish" unless release_finish.wait(5)
      end

      method.call(*args, **kwargs)
    end
    allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction)
      .and_wrap_original do |method, entry, *args, &block|
        if Thread.current[:finish_move_out_batch] && entry.is_a?(Sprint) && entry.id == source_sprint.id
          batch_progress << :source_lock_attempted
        end
        method.call(entry, *args, &block)
      end

    finish_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Thread.current[:finish_move_out_race] = true
        Backlogs::Sprints::FinishService
          .new(user:, model: source_sprint)
          .call(unfinished_action: "move_to_top_of_backlog")
      end
    end
    raise "sprint finish did not enumerate its cohort" unless finish_paused.wait(5)

    batch_thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Thread.current[:finish_move_out_batch] = true
        result = move_service.call(list_type: "backlog_bucket", list_id: empty_bucket.id.to_s)
        batch_result << result
        batch_progress << :batch_finished
      end
    end

    observed_progress = Timeout.timeout(5) { batch_progress.pop }
    release_finish.set
    finish_result = finish_thread.value
    batch_thread.value
    move_result = Timeout.timeout(5) { batch_result.pop }

    expect(observed_progress).to eq :source_lock_attempted
    expect(finish_result).to be_success
    expect(move_result).to be_failure
    expect(move_result.message)
      .to eq I18n.t("backlogs.work_packages.batch_update_service.stale_batch")
    expect(source_sprint.reload).to be_completed
    expect(WorkPackage.where(id: original_cohort).pluck(:sprint_id)).to all(be_nil)
    expect(WorkPackage.where(id: original_cohort).pluck(:backlog_bucket_id)).to all(be_nil)
    expect(empty_bucket.work_packages).to be_empty
  ensure
    cleanup_concurrency_threads(
      release_events: [release_finish],
      threads: [finish_thread, batch_thread]
    )
  end
  # rubocop:enable RSpec/ExampleLength

  it "terminates a thread that misses the cleanup deadline and reports the cleanup failure" do
    release = Concurrent::Event.new
    blocker = Queue.new
    thread = Thread.new do
      release.wait
      blocker.pop
    end
    thread.report_on_exception = false

    expect do
      cleanup_concurrency_threads(release_events: [release], threads: [thread], join_timeout: 0.01)
    end.to raise_error(RuntimeError, /did not stop during concurrency cleanup/)
    expect(release).to be_set
    expect(thread).not_to be_alive
  ensure
    thread&.kill
    thread&.join
  end

  it "stops all workers and reports a worker failure when no example failure is propagating" do
    failed_thread = Thread.new { raise "worker failure" }
    failed_thread.report_on_exception = false
    blocker = Queue.new
    lingering_thread = Thread.new { blocker.pop }
    lingering_thread.report_on_exception = false
    Timeout.timeout(5) { Thread.pass while failed_thread.alive? }

    expect do
      cleanup_concurrency_threads(
        release_events: [],
        threads: [failed_thread, lingering_thread],
        join_timeout: 0.01
      )
    end.to raise_error(RuntimeError, "worker failure")
    expect(failed_thread).not_to be_alive
    expect(lingering_thread).not_to be_alive
  ensure
    lingering_thread&.kill
    lingering_thread&.join
  end

  it "keeps an original failure authoritative while stopping failed and lingering workers" do
    failed_thread = Thread.new { raise "worker failure" }
    failed_thread.report_on_exception = false
    blocker = Queue.new
    lingering_thread = Thread.new { blocker.pop }
    lingering_thread.report_on_exception = false
    Timeout.timeout(5) { Thread.pass while failed_thread.alive? }

    expect do
      raise "original failure"
    ensure
      cleanup_concurrency_threads(
        release_events: [],
        threads: [failed_thread, lingering_thread],
        join_timeout: 0.01
      )
    end.to raise_error(RuntimeError, "original failure")
    expect(failed_thread).not_to be_alive
    expect(lingering_thread).not_to be_alive
  ensure
    lingering_thread&.kill
    lingering_thread&.join
  end
end
