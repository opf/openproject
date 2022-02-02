shared_examples 'notification settings workflow' do
  describe 'with another project the user can see' do
    let!(:project) { create :project }
    let!(:project_alt) { create :project }
    let!(:role) { create :role, permissions: %i[view_project] }
    let!(:member) { create :member, user: user, project: project, roles: [role] }
    let!(:member_two) { create :member, user: user, project: project_alt, roles: [role] }

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
      expect(notification_settings.count).to eq 3
      expect(notification_settings.where(project: project).count).to eq 1

      project_settings = notification_settings.find_by(project: project)
      expect(project_settings.involved).to be_truthy
      expect(project_settings.mentioned).to be_truthy
      expect(project_settings.watched).to be_truthy
      expect(project_settings.work_package_commented).to be_falsey
      expect(project_settings.work_package_created).to be_falsey
      expect(project_settings.work_package_processed).to be_falsey
      expect(project_settings.work_package_prioritized).to be_falsey
      expect(project_settings.work_package_scheduled).to be_falsey

      # Trying to add the same project again will not be possible (Regression #38072)
      click_button 'Add setting for project'
      container = page.find('[data-qa-selector="notification-setting-inline-create"] ng-select')
      settings_page.search_autocomplete container, query: project.name, results_selector: 'body'
      expect(page).to have_text 'This project is already selected'
      expect(page).to have_selector('.ng-option-disabled', text: project.name)
    end
  end
end
