require 'rails_helper'

describe "Date alert settings", js: true do
  current_user { create(:user) }

  let(:settings_page) { Pages::My::Notifications.new(current_user) }
  let(:user) { current_user }
  let!(:project) { create(:project) }
  let!(:project_alt) { create(:project) }
  let!(:role) { create(:role, permissions: %i[view_project]) }
  let!(:member) { create(:member, user:, project:, roles: [role]) }
  let!(:member_two) { create(:member, user:, project: project_alt, roles: [role]) }

  it 'allows to configure the date alert settings' do
    settings_page.visit!
    settings_page.set_time('op-reminder-settings-start-date-alerts', '3 days before')
    settings_page.date_alert_option('overdue', true)
    settings_page.set_time('op-reminder-settings-overdue-date-alerts', 'every week')

    settings_page.save

    user.reload
    notification_settings = user.notification_settings

    expect(notification_settings.count).to eq(1)
    expect(notification_settings.first.start_date).to eq(3)
    expect(notification_settings.first.due_date).to eq(1)
    expect(notification_settings.first.overdue).to eq(7)
  end

  it 'allows to configure date alerts settings per project' do
    settings_page.visit!
    settings_page.add_project project

    settings_page.set_time('op-reminder-settings-start-date-alerts-global', '3 days before')
    settings_page.set_time('op-reminder-settings-due-date-alerts-global', '3 days before')
    settings_page.set_time('op-reminder-settings-overdue-date-alerts-global', 'every week')
    settings_page.save

    user.reload
    notification_settings = user.notification_settings

    expect(notification_settings.count).to eq 2
    expect(notification_settings.where(project:).count).to eq 1
    expect(notification_settings.where(project:).first.start_date).to eq(3)
    expect(notification_settings.where(project:).first.due_date).to eq(3)
    expect(notification_settings.where(project:).first.overdue).to eq(7)
  end
end
