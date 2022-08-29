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

  it 'updates finish date of work packages after marking week days as non-working' do
    work_package = create(:work_package,
                          ignore_non_working_days: false,
                          start_date: Date.parse('Mon 2022-08-22'),
                          duration: 5)

    expect do
      set_non_working_week_day('wednesday')
      job.perform_now(user_id: user.id)
    end
      .to change { work_package.reload.slice(:due_date) }
      .from(due_date: Date.parse('Fri 2022-08-26'))
      .to(due_date: Date.parse('Mon 2022-08-29'))
  end

  it 'does not change work packages ignoring non-working days' do
    work_package = create(:work_package,
                          ignore_non_working_days: true,
                          start_date: Date.parse('Mon 2022-08-22'),
                          duration: 5)

    expect do
      set_non_working_week_day('wednesday')
      job.perform_now(user_id: user.id)
    end
      .not_to change { work_package.reload }
  end

  it 'updates multiple work packages' do
    create_list(:work_package,
                5,
                ignore_non_working_days: false,
                start_date: Date.parse('Mon 2022-08-22'),
                duration: 5)

    set_non_working_week_day('wednesday')
    job.perform_now(user_id: user.id)

    new_due_dates = WorkPackage.order(:id).pluck(:due_date)
    expect(new_due_dates).to all(eq(Date.parse('Mon 2022-08-29')))
  end

  it 'updates followers if needed' do
    work_package = create(:work_package,
                          ignore_non_working_days: false,
                          start_date: Date.parse('Mon 2022-08-22'),
                          duration: 5)
    follower = create(:work_package,
                      ignore_non_working_days: true,
                      start_date: Date.parse('Sat 2022-08-27'),
                      duration: 2)
    create(:follows_relation, from: follower, to: work_package)

    set_non_working_week_day('wednesday')
    job.perform_now(user_id: user.id)

    follower.reload
    work_package.reload
    expect(follower.start_date).not_to eq(Date.parse('Sat 2022-08-27'))
    expect(follower.start_date).to eq(work_package.due_date + 1)
    expect(follower.due_date).to eq(work_package.due_date + 2)
  end
end
