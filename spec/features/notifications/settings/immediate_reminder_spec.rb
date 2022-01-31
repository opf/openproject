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

      reminders_settings_page.expect_and_dismiss_toaster(message: I18n.t('js.notice_successful_update'))

      reminders_settings_page.reload!

      reminders_settings_page.expect_immediate_reminder :mentioned, true

      expect(pref.reload.immediate_reminders[:mentioned]).to eq true
    end
  end

  context 'with the my page' do
    let(:reminders_settings_page) { Pages::My::Reminders.new(current_user) }
    let(:pref) { current_user.pref }

    current_user do
      create :user
    end

    it_behaves_like 'immediate reminder settings'
  end

  context 'with the user administration page' do
    let(:reminders_settings_page) { Pages::Reminders::Settings.new(other_user) }

    let(:other_user) { create :user }
    let(:pref) { other_user.pref }

    current_user do
      create :admin
    end

    it_behaves_like 'immediate reminder settings'
  end

  describe 'email sending', js: false do
    let(:project) { create(:project) }
    let(:work_package) { create(:work_package, project: project) }
    let(:receiver) do
      create(
        :user,
        preferences: {
          immediate_reminders: {
            mentioned: true
          }
        },
        notification_settings: [
          build(:notification_setting,
                           mentioned: true)
        ],
        member_in_project: project,
        member_with_permissions: %i[view_work_packages]
      )
    end

    current_user do
      create(:user)
    end

    it 'sends a mail to the mentioned user immediately' do
      perform_enqueued_jobs do
        note = <<~NOTE
          Hey <mention class=\"mention\"
                       data-id=\"#{receiver.id}\"
                       data-type=\"user\"
                       data-text=\"@#{receiver.name}\">
                @#{receiver.name}
              </mention>
        NOTE

        work_package.add_journal(current_user, note)
        work_package.save!
      end

      expect(ActionMailer::Base.deliveries.length)
        .to be 1

      expect(ActionMailer::Base.deliveries.first.subject)
        .to eql I18n.t(:'mail.mention.subject',
                       user_name: current_user.name,
                       id: work_package.id,
                       subject: work_package.subject)
    end
  end
end
