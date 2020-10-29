require 'spec_helper'

describe ActiveJob do

  class CronJob < ActiveJob::Base
    class_attribute :cron

    def perform; end

    def cron
      @cron ||= self.class.cron
    end
  end

  before { Delayed::Job.delete_all }

  let(:cron)    { '5 1 * * *' }
  let(:job)     { CronJob.set(cron: cron).perform_later }
  let(:delayed_job) { Delayed::Job.first }
  let(:worker)  { Delayed::Worker.new }
  let(:now)     { Delayed::Job.db_time_now }
  let(:next_run) do
    run = now.hour * 60 + now.min >= 65 ? now + 1.day : now
    Time.utc(run.year, run.month, run.day, 1, 5)
  end

  context 'with cron' do
    it 'sets run_at on enqueue' do
      expect { job }.to change { Delayed::Job.count }.by(1)
      expect(delayed_job.run_at).to eq(next_run)
      expect(delayed_job.cron).to eq(cron)
    end

    it 'schedules a new job after success' do
      job
      delayed_job.update_column(:run_at, now)
      delayed_job.reload

      worker.work_off

      expect(Delayed::Job.count).to eq(1)
      j = Delayed::Job.first
      expect(j.id).to eq(delayed_job.id)
      expect(j.cron).to eq(delayed_job.cron)
      expect(j.run_at).to eq(next_run)
      expect(j.attempts).to eq(1)
      expect(j.last_error).to eq(nil)
      expect(j.created_at).to eq(delayed_job.created_at)
    end
  end

  context 'without cron' do
    let(:job) { CronJob.perform_later }

    it 'sets run_at but not cron on enqueue' do
      CronJob.cron = nil
      expect { job }.to change { Delayed::Job.count }.by(1)
      expect(delayed_job.run_at).to be <= now
      expect(delayed_job.cron).to be_nil
    end

    it 'uses default cron on enqueue' do
      CronJob.cron = cron
      expect { job }.to change { Delayed::Job.count }.by(1)
      expect(delayed_job.run_at).to eq(next_run)
      expect(delayed_job.cron).to eq(cron)
    end
  end
end