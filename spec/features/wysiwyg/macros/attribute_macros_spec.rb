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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe 'Wysiwyg attribute macros', type: :feature, js: true do
  shared_let(:admin) { create :admin }
  let(:user) { admin }
  let!(:project) { create(:project, identifier: 'some-project', enabled_module_names: %w[wiki work_package_tracking]) }
  let!(:work_package) { create(:work_package, subject: "Foo Bar", project: project) }
  let(:editor) { ::Components::WysiwygEditor.new }

  let(:markdown) do
    <<~MD
      # My headline

      <table>
        <thead>
        <tr>
          <th>Label</th>
          <th>Value</th>
        </tr>
        </thead>
        <tbody>
        <tr>
          <td>workPackageLabel:"Foo Bar":subject</td>
          <td>workPackageValue:"Foo Bar":subject</td>
        </tr>
        <tr>
          <td>projectLabel:identifier</td>
          <td>projectValue:identifier</td>
        </tr>
        <tr>
          <td>invalid subject workPackageValue:"Invalid":subject</td>
          <td>invalid project projectValue:"does not exist":identifier</td>
        </tr>
        </tbody>
      </table>
    MD
  end

  before do
    login_as(user)
  end

  describe 'in wikis' do
    describe 'creating a wiki page' do
      before do
        visit project_wiki_path(project, :wiki)
      end

      it 'can add and save multiple code blocks (Regression #28350)' do
        editor.in_editor do |container,|
          editor.set_markdown markdown
          expect(container).to have_selector('table')
        end

        click_on 'Save'

        expect(page).to have_selector('.flash.notice')

        # Expect output widget
        within('#content') do
          expect(page).to have_selector('td', text: 'Subject')
          expect(page).to have_selector('td', text: 'Foo Bar')
          expect(page).to have_selector('td', text: 'Identifier')
          expect(page).to have_selector('td', text: 'some-project')

          expect(page).to have_selector('td', text: 'invalid subject Cannot expand macro: Requested resource could not be found')
          expect(page).to have_selector('td', text: 'invalid project Cannot expand macro: Requested resource could not be found')
        end

        # Edit page again
        click_on 'Edit'

        editor.in_editor do |container,|
          expect(container).to have_selector('tbody td', count: 6)
        end
      end
    end
  end
end
