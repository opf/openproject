require 'spec_helper'

describe DelayedCronJob do

  class TestJob
    def perform; end
  end

  class DatabaseDisconnectPlugin < Delayed::Plugin

    callbacks do |lifecycle|
      lifecycle.after(:perform) do
        ActiveRecord::Base.connection.disconnect!
      end
    end

  end

  before { Delayed::Job.delete_all }

  let(:cron)    { '5 1 * * *' }
  let(:handler) { TestJob.new }
  let(:job)     { Delayed::Job.enqueue(handler, cron: cron) }
  let(:worker)  { Delayed::Worker.new }
  let(:now)     { Delayed::Job.db_time_now }
  let(:next_run) do
    run = now.hour * 60 + now.min >= 65 ? now + 1.day : now
    Time.utc(run.year, run.month, run.day, 1, 5)
  end

  context 'with cron' do
    it 'sets run_at on enqueue' do
      expect { job }.to change { Delayed::Job.count }.by(1)
      expect(job.run_at).to eq(next_run)
    end

    it 'enqueue fails with invalid cron' do
      expect { Delayed::Job.enqueue(handler, cron: 'no valid cron') }
        .to raise_error(ArgumentError)
    end

    it 'schedules a new job after success' do
      job.update_column(:run_at, now)
      job.reload # adjusts granularity of run_at datetime

      worker.work_off

      expect(Delayed::Job.count).to eq(1)
      j = Delayed::Job.first
      expect(j.id).to eq(job.id)
      expect(j.cron).to eq(job.cron)
      expect(j.run_at).to eq(next_run)
      expect(j.attempts).to eq(1)
      expect(j.last_error).to eq(nil)
      expect(j.created_at).to eq(job.created_at)
    end

    it 'schedules a new job after failure' do
      allow_any_instance_of(TestJob).to receive(:perform).and_raise('Fail!')
      job.update(run_at: now)
      job.reload # adjusts granularity of run_at datetime

      worker.work_off

      expect(Delayed::Job.count).to eq(1)
      j = Delayed::Job.first
      expect(j.id).to eq(job.id)
      expect(j.cron).to eq(job.cron)
      expect(j.run_at).to eq(next_run)
      expect(j.last_error).to match('Fail!')
      expect(j.created_at).to eq(job.created_at)
    end

    it 'schedules a new job after timeout' do
      Delayed::Worker.max_run_time = 1.second
      job.update_column(:run_at, now)
      allow_any_instance_of(TestJob).to receive(:perform) { sleep 2 }

      worker.work_off

      expect(Delayed::Job.count).to eq(1)
      j = Delayed::Job.first
      expect(j.id).to eq(job.id)
      expect(j.cron).to eq(job.cron)
      expect(j.run_at).to eq(next_run)
      expect(j.attempts).to eq(1)
      expect(j.last_error).to match('execution expired')
    end

    it 'does not schedule new job after deserialization error' do
      job.update_column(:run_at, now)
      allow_any_instance_of(TestJob).to receive(:perform).and_raise(Delayed::DeserializationError)

      worker.work_off

      expect(Delayed::Job.count).to eq(0)
    end

    it 'has empty last_error after success' do
      job.update(run_at: now, last_error: 'Last error')

      worker.work_off

      j = Delayed::Job.first
      expect(j.last_error).to eq(nil)
    end

    it 'has updated last_error after failure' do
      allow_any_instance_of(TestJob).to receive(:perform).and_raise('Fail!')
      job.update(run_at: now, last_error: 'Last error')

      worker.work_off

      j = Delayed::Job.first
      expect(j.last_error).to match('Fail!')
    end

    it 'uses correct db time for next run' do
      if Time.now != now
        job = Delayed::Job.enqueue(handler, cron: '* * * * *')
        run = now.hour == 23 && now.min == 59 ? now + 1.day : now
        hour = now.min == 59 ? (now.hour + 1) % 24 : now.hour
        run_at = Time.utc(run.year, run.month, run.day, hour, (now.min + 1) % 60)
        expect(job.run_at).to eq(run_at)
      else
        pending 'This test only makes sense in non-UTC time zone'
      end
    end

    it 'increases attempts on each run' do
      job.update(run_at: now, attempts: 3)

      worker.work_off

      j = Delayed::Job.first
      expect(j.attempts).to eq(4)
    end

    it 'is not stopped by max attempts' do
      job.update(run_at: now, attempts: Delayed::Worker.max_attempts + 1)

      worker.work_off

      expect(Delayed::Job.count).to eq(1)
      j = Delayed::Job.first
      expect(j.attempts).to eq(job.attempts + 1)
    end

    it 'updates run_at if cron is changed' do
      job.update!(cron: '1 10 * * *')
      expect(job.run_at.min).to eq(1)
    end

    it 'uses new cron when this is updated while job is running' do
      job.update_column(:run_at, now)
      allow_any_instance_of(TestJob).to receive(:perform) { job.update!(cron: '1 10 * * *') }

      worker.work_off

      j = Delayed::Job.first
      expect(j.run_at.min).to eq(1)
    end

    it 'does not reschedule job if cron is cleared while job is running' do
      job.update_column(:run_at, now)
      allow_any_instance_of(TestJob).to receive(:perform) { job.update!(cron: '') }

      expect { worker.work_off }.to change { Delayed::Job.count }.by(-1)
    end

    it 'does not reschedule job if model is deleted while job is running' do
      job.update_column(:run_at, now)
      allow_any_instance_of(TestJob).to receive(:perform) { job.destroy! }

      expect { worker.work_off }.to change { Delayed::Job.count }.by(-1)
    end

    context 'when database connection is lost' do
      around(:each) do |example|
        Delayed::Worker.plugins.unshift DatabaseDisconnectPlugin
        # hold onto a connection so the in-memory database isn't lost when disconnected
        temp_connection = ActiveRecord::Base.connection_pool.checkout
        example.run
        ActiveRecord::Base.connection_pool.checkin temp_connection
        Delayed::Worker.plugins.delete DatabaseDisconnectPlugin
      end

      it 'does not lose the job if database connection is lost' do
        job.update_column(:run_at, now)
        job.reload # adjusts granularity of run_at datetime

        begin
          worker.work_off
        rescue StandardError
          # Attempting to save the clone delayed_job will raise an exception due to the database connection being closed
        end

        ActiveRecord::Base.connection.reconnect!

        expect(Delayed::Job.count).to eq(1)
        j = Delayed::Job.first
        expect(j.id).to eq(job.id)
        expect(j.cron).to eq(job.cron)
        expect(j.attempts).to eq(0)
      end
    end
  end

  context 'without cron' do
    it 'reschedules the original job after a single failure' do
      allow_any_instance_of(TestJob).to receive(:perform).and_raise('Fail!')
      job = Delayed::Job.enqueue(handler)

      worker.work_off

      expect(Delayed::Job.count).to eq(1)
      j = Delayed::Job.first
      expect(j.id).to eq(job.id)
      expect(j.cron).to eq(nil)
      expect(j.last_error).to match('Fail!')
    end

    it 'does not reschedule a job after a successful run' do
      Delayed::Job.enqueue(handler)

      worker.work_off

      expect(Delayed::Job.count).to eq(0)
    end
  end
end
