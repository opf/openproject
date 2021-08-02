shared_examples 'notification settings workflow' do
  describe 'with another project the user can see' do
    let!(:project) { FactoryBot.create :project }
    let!(:role) { FactoryBot.create :role, permissions: %i[view_project] }
    let!(:member) { FactoryBot.create :member, user: user, project: project, roles: [role] }

    it 'allows to control notification settings' do
      # Expect default settings
      settings_page.expect_represented

      # Add setting for the project
      settings_page.add_row project

      # Set settings for project email
      settings_page.configure_channel :mail,
                                      project: project,
                                      involved: true,
                                      mentioned: true,
                                      watched: true,
                                      all: false

      # Set settings for project email
      settings_page.configure_channel :in_app,
                                      project: project,
                                      involved: true,
                                      mentioned: true,
                                      watched: false,
                                      all: false

      # Set settings for project email digest
      settings_page.configure_channel :mail_digest,
                                      project: project,
                                      involved: false,
                                      mentioned: true,
                                      watched: false,
                                      all: true

      settings_page.save

      user.reload
      notification_settings = user.notification_settings
      expect(notification_settings.count).to eq 6
      expect(notification_settings.where(project: project).count).to eq 3

      in_app = notification_settings.find_by(project: project, channel: :in_app)
      expect(in_app.involved).to be_truthy
      expect(in_app.mentioned).to be_truthy
      expect(in_app.watched).to be_falsey
      expect(in_app.all).to be_falsey

      in_app = notification_settings.find_by(project: project, channel: :mail)
      expect(in_app.involved).to be_truthy
      expect(in_app.mentioned).to be_truthy
      expect(in_app.watched).to be_truthy
      expect(in_app.all).to be_falsey

      in_app = notification_settings.find_by(project: project, channel: :mail_digest)
      expect(in_app.involved).to be_falsey
      expect(in_app.mentioned).to be_truthy
      expect(in_app.watched).to be_falsey
      expect(in_app.all).to be_truthy

      # Trying to add the same project again will not be possible (Regression #38072)
      click_button 'Add setting for project'
      container = page.find('[data-qa-selector="notification-setting-inline-create"] ng-select')
      settings_page.search_autocomplete container, query: project.name, results_selector: 'body'
      expect(page).to have_text 'This project is already selected'
      expect(page).to have_selector('.ng-option-disabled', text: project.name)
    end
  end
end
