#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
require_relative '../support/pages/work_package_github_tab'

describe 'Open the GitHub tab', js: true do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:role) do
    FactoryBot.create(:role,
                      permissions: %i(view_work_packages
                                      add_work_package_notes
                                      show_github_content))
  end
  let(:project) { FactoryBot.create :project }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:github_tab) { Pages::GitHubTab.new(work_package.id) }

  shared_examples_for "a github tab" do
    before do
      login_as(user)
      work_package
    end

    # compares the clipboard content by drafting a new comment, pressing ctrl+v and
    # comparing the pasted content against the provided text
    def expect_clipboard_content(text)
      work_package_page.switch_to_tab(tab: 'activity')

      work_package_page.trigger_edit_comment
      work_package_page.update_comment(' ') # ensure the comment editor is fully loaded
      github_tab.paste_clipboard_content
      expect(work_package_page.add_comment_container).to have_content(text)

      work_package_page.switch_to_tab(tab: 'github')
    end

    it 'show the github tab when the user is allowed to see it' do
      work_package_page.visit!
      work_package_page.switch_to_tab(tab: 'github')
      expect(page).to have_content('There are no Pull Requests')
      expect(page).to have_content("Link an existing PR by using the code OP##{work_package.id}")

      github_tab.git_actions_menu_button.click()
      github_tab.git_actions_copy_button.click()
      expect(page).to have_text('Copied!')
      expect_clipboard_content("#{work_package.type.name.downcase}/#{work_package.id}-workpackage-no-#{work_package.id}")
    end

    describe 'when the user does not have the permissions to see the github tab' do
      let(:role) do
        FactoryBot.create(:role,
                          permissions: %i(view_work_packages
                                          add_work_package_notes))
      end

      it 'does not show the github tab' do
        work_package_page.visit!

        github_tab.expect_tab_not_present
      end
    end

    describe 'when the github integration is not enabled for the project' do
      let(:project) { FactoryBot.create(:project, disable_modules: 'github') }

      it 'does not show the github tab' do
        work_package_page.visit!

        github_tab.expect_tab_not_present
      end
    end
  end
  
  describe 'work package full view' do
    let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
    
    it_behaves_like 'a github tab'
  end
  
  describe 'work package split view' do
    let(:work_package_page) { Pages::SplitWorkPackage.new(work_package) }

    it_behaves_like 'a github tab'
  end
end
