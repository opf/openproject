shared_examples 'notification settings workflow' do
  describe 'with another project the user can see' do
    let!(:project) { FactoryBot.create :project }
    let!(:role) { FactoryBot.create :role, permissions: %i[view_project] }
    let!(:member) { FactoryBot.create :member, user: user, project: project, roles: [role] }

    let(:settings_page) { ::Pages::Notifications::Settings.new(user) }

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

      settings_page.save

      user.reload
      notification_settings = user.notification_settings
      expect(notification_settings.count).to eq 4
      expect(notification_settings.where(project: project).count).to eq 2

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
    end
  end
end
