shared_examples 'notification settings workflow' do
  describe 'with another project the user can see' do
    let!(:project) { FactoryBot.create :project }
    let!(:project_alt) { FactoryBot.create :project }
    let!(:role) { FactoryBot.create :role, permissions: %i[view_project] }
    let!(:member) { FactoryBot.create :member, user: user, project: project, roles: [role] }
    let!(:member_two) { FactoryBot.create :member, user: user, project: project_alt, roles: [role] }

    it 'allows to control notification settings' do
      # Expect default settings
      settings_page.expect_represented

      # Add projects columns
      settings_page.add_project project
      settings_page.add_project project_alt

      # Set settings for project email
      settings_page.configure_global involved: true,
                                     work_package_commented: true,
                                     work_package_created: true,
                                     work_package_processed: true,
                                     work_package_prioritized: true,
                                     work_package_scheduled: true

      # Set settings for project email
      settings_page.configure_project project: project,
                                      involved: true,
                                      work_package_commented: false,
                                      work_package_created: false,
                                      work_package_processed: false,
                                      work_package_prioritized: false,
                                      work_package_scheduled: false

      settings_page.save

      user.reload
      notification_settings = user.notification_settings
      expect(notification_settings.count).to eq 9
      expect(notification_settings.where(project: project).count).to eq 3

      in_app = notification_settings.find_by(project: project)
      expect(in_app.involved).to be_truthy
      expect(in_app.mentioned).to be_truthy
      expect(in_app.watched).to be_truthy
      expect(in_app.work_package_commented).to be_falsey
      expect(in_app.work_package_created).to be_falsey
      expect(in_app.work_package_processed).to be_falsey
      expect(in_app.work_package_prioritized).to be_falsey
      expect(in_app.work_package_scheduled).to be_falsey

      # Trying to add the same project again will not be possible (Regression #38072)
      click_button 'Add setting for project'
      container = page.find('[data-qa-selector="notification-setting-inline-create"] ng-select')
      settings_page.search_autocomplete container, query: project.name, results_selector: 'body'
      expect(page).to have_text 'This project is already selected'
      expect(page).to have_selector('.ng-option-disabled', text: project.name)
    end
  end
end
