require 'rails_helper'

RSpec.describe WorkPackages::ApplyWorkingDaysChangeJob,
               with_flag: { work_packages_duration_field_active: true } do
  subject(:job) { described_class }

  shared_let(:user) { create(:user) }
  shared_let(:week_days) { create(:week_days_with_saturday_and_sunday_as_weekend) }

  def set_non_working_week_day(day)
    wday = %w[xxx monday tuesday wednesday thursday friday saturday sunday].index(day.downcase)
    WeekDay.find_by(day: wday).update(working: false)
  end

  context 'when a work package includes a date that is now a non-working day' do
    let_schedule(<<~CHART, ignore_non_working_days: false)
      days          | MTWTFSS |
      work_package  | XXXX    |
    CHART

    before do
      set_non_working_week_day('wednesday')
    end

    it 'moves the finish date to the corresponding number of now-excluded days to maintain duration [#31992]' do
      job.perform_now(user_id: user.id)
      expect(WorkPackage.all).to match_schedule(<<~CHART)
        days         | MTWTFSS |
        work_package | XX.XX   |
      CHART
    end
  end

  context 'when a work package includes a date that is now a non-working day, but has working days include weekends' do
    let_schedule(<<~CHART)
      days          | MTWTFSS |
      work_package  | XXXX    | working days include weekends
    CHART

    before do
      set_non_working_week_day('wednesday')
    end

    it 'does not move any dates' do
      job.perform_now(user_id: user.id)
      expect(WorkPackage.all).to match_schedule(<<~CHART)
        days         | MTWTFSS |
        work_package | XXXX    | working days include weekends
      CHART
    end
  end

  context 'when having multiple work packages' do
    let_schedule(<<~CHART, ignore_non_working_days: false)
      days | MTWTFSS |
      wp1  | XX      |
      wp2  |  XX     |
      wp3  |   XX    |
      wp4  |    XX   |
      wp5  | XXXXX   |
    CHART

    before do
      set_non_working_week_day('wednesday')
    end

    it 'updates all impacted work packages' do
      job.perform_now(user_id: user.id)
      expect(WorkPackage.all).to match_schedule(<<~CHART)
        days | MTWTFSS  |
        wp1  | XX       |
        wp2  |  X.X     |
        wp3  |    XX    |
        wp4  |    XX    |
        wp5  | XX.XX..X |
      CHART
    end
  end

  context 'when a work package was scheduled to start on a date that is now a non-working day' do
    let_schedule(<<~CHART, ignore_non_working_days: false)
      days          | MTWTFSS |
      work_package  |   XX    |
    CHART

    before do
      set_non_working_week_day('wednesday')
    end

    it 'moves the start date to the earliest working day in the future, ' \
       'and the finish date changes by consequence [#31992]' do
      job.perform_now(user_id: user.id)
      expect(WorkPackage.all).to match_schedule(<<~CHART)
        days         | MTWTFSS |
        work_package |    XX   |
      CHART
    end
  end

  context 'when a follower has a predecessor with dates covering a day that is now a non-working day' do
    let_schedule(<<~CHART)
      days        | MTWTFSS |
      predecessor |  XX     | working days work week
      follower    |    XXX  | working days include weekends, follows predecessor
    CHART

    before do
      set_non_working_week_day('wednesday')
    end

    it 'moves the follower start date by consequence of the predecessor dates shift [#31992]' do
      job.perform_now(user_id: user.id)
      expect(WorkPackage.all).to match_schedule(<<~CHART)
        days        | MTWTFSS |
        predecessor |  X.X    | working days work week
        follower    |     XXX | working days include weekends
      CHART
    end
  end
end
