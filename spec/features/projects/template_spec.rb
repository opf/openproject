#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Project templates', type: :feature, js: true do
  describe 'making project a template' do
    let(:project) { FactoryBot.create :project }
    using_shared_fixtures :admin

    before do
      login_as admin
    end

    it 'can make the project a template from settings' do
      visit settings_generic_project_path(project)

      # Make a template
      find('.button', text: 'Set as template').click

      expect(page).to have_selector('.button', text: 'Remove from templates')
      project.reload
      expect(project).to be_templated

      # unset template
      find('.button', text: 'Remove from templates').click
      expect(page).to have_selector('.button', text: 'Set as template')

      project.reload
      expect(project).not_to be_templated
    end
  end

  describe 'instantiating templates' do
    let!(:template) {
      FactoryBot.create(:template_project, name: 'My template', enabled_module_names: %w[wiki work_package_tracking])
    }
    let!(:template_status) { FactoryBot.create(:project_status, project: template, explanation: 'source') }
    let!(:other_project) { FactoryBot.create(:project, name: 'Some other project') }
    let!(:work_package) { FactoryBot.create :work_package, project: template }
    let!(:wiki_page) { FactoryBot.create(:wiki_page_with_content, wiki: template.wiki) }

    let!(:role) { FactoryBot.create(:role, permissions: %i[view_project view_work_packages copy_projects add_subprojects add_project]) }
    let!(:current_user) { FactoryBot.create(:user, member_in_projects: [template, other_project], member_through_role: role) }
    let(:status_field_selector) { 'ckeditor-augmented-textarea[textarea-selector="#project_status_explanation"]' }
    let(:status_description) { ::Components::WysiwygEditor.new status_field_selector }

    before do
      login_as current_user
    end

    it 'can instantiate the project with the copy permission' do
      visit new_project_path

      fill_in 'project[name]', with: 'Foo bar'

      # Choosing template reloads the page and sets advanced settings
      select 'My template', from: 'project-select-template'

      # It reloads the page without any warning dialog and keeps the name
      expect(page).to have_field 'Name', with: 'Foo bar'
      expect(page).to have_select 'project-select-template', selected: 'My template'

      # Updates the identifier in advanced settings
      page.find('#advanced-settings').click
      expect(page).to have_field 'project_identifier', with: 'foo-bar'
      expect(page).to have_select 'project_status_code', selected: 'On track'

      # Changing the template now causes a dialog
      select '(none)', from: 'project-select-template'
      page.driver.browser.switch_to.alert.accept

      # Choosing template reloads the page and sets advanced settings
      select 'My template', from: 'project-select-template'

      # It reloads the page without any warning dialog and keeps the name
      expect(page).to have_field 'Name', with: 'Foo bar'
      expect(page).to have_select 'project-select-template', selected: 'My template'

      # Expend advanced settings
      page.find('#advanced-settings').click
      expect(page).to have_field 'project_identifier', with: 'foo-bar'
      expect(page).to have_select 'project_status_code', selected: 'On track'

      # Update status to off track
      select 'Off track', from: 'project_status_code'
      select other_project.name, from: 'project_parent_id'

      click_on 'Create'

      expect(page).to have_content I18n.t('project.template.copying')
      expect(page).to have_content I18n.t('js.job_status.generic_messages.in_queue')
      expect(page).to have_current_path /\/job_statuses\/[\w-]+/

      # Email notification should be sent
      perform_enqueued_jobs

      mail = ActionMailer::Base
        .deliveries
        .detect { |mail| mail.subject == 'Created project Foo bar' }

      expect(mail).not_to be_nil

      expect(page).to have_current_path '/projects/foo-bar/', wait: 20

      project = Project.find_by identifier: 'foo-bar'
      expect(project.name).to eq 'Foo bar'
      expect(project).not_to be_templated
      expect(project.users.first).to eq current_user
      expect(project.enabled_module_names.sort).to eq(template.enabled_module_names.sort)

      wp_source = template.work_packages.first.attributes.except(*%w[id author_id project_id updated_at created_at])
      wp_target = project.work_packages.first.attributes.except(*%w[id author_id project_id updated_at created_at])
      expect(wp_source).to eq(wp_target)

      wiki_source = template.wiki.pages.first
      wiki_target = project.wiki.pages.first
      expect(wiki_source.title).to eq(wiki_target.title)
      expect(wiki_source.content.text).to eq(wiki_target.content.text)
    end
  end
end

