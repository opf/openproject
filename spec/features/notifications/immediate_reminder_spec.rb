require 'spec_helper'

describe "Immediate reminder settings", type: :feature, js: true do
  shared_examples 'immediate reminder settings' do
    it 'allows to configure the reminder settings' do
      # Save prefs so we can reload them later
      pref.save!

      # Configure the reminders
      reminders_settings_page.visit!

      # By default the immediate reminder is unchecked
      expect(pref.immediate_reminders[:mentioned]).to eq false
      reminders_settings_page.expect_immediate_reminder :mentioned, false

      reminders_settings_page.set_immediate_reminder :mentioned, true

      reminders_settings_page.save

      reminders_settings_page.expect_and_dismiss_notification(message: I18n.t('js.notice_successful_update'))

      reminders_settings_page.reload!

      reminders_settings_page.set_immediate_reminder :mentioned, true

      expect(pref.reload.immediate_reminders[:mentioned]).to eq true
    end
  end

  context 'with the my page' do
    let(:reminders_settings_page) { Pages::My::Reminders.new(current_user) }
    let(:pref) { current_user.pref }

    current_user do
      FactoryBot.create :user
    end

    it_behaves_like 'immediate reminder settings'
  end

  context 'with the user administration page' do
    let(:reminders_settings_page) { Pages::Reminders::Settings.new(other_user) }

    let(:other_user) { FactoryBot.create :user }
    let(:pref) { other_user.pref }

    current_user do
      FactoryBot.create :admin
    end

    it_behaves_like 'immediate reminder settings'
  end
end
