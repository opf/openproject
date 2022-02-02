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

describe 'Wysiwyg work package quicklink macros', type: :feature, js: true do
  shared_let(:admin) { create :admin }
  let(:user) { admin }
  let!(:project) { create(:project, identifier: 'some-project', enabled_module_names: %w[wiki work_package_tracking]) }
  let!(:work_package) do
    create(:work_package, subject: "Foo Bar", project: project, start_date: '2020-01-01', due_date: '2020-02-01')
  end
  let(:editor) { ::Components::WysiwygEditor.new }

  let(:markdown) do
    <<~MD
      # My headline

      ###{work_package.id}

      ####{work_package.id}
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
          expect(container).to have_selector('p', text: "###{work_package.id}")
          expect(container).to have_selector('p', text: "####{work_package.id}")
        end

        click_on 'Save'

        expect(page).to have_selector('.flash.notice')

        # Expect output widget
        within('#content') do
          expect(page).to have_selector('macro', count: 2)
          expect(page).to have_selector('span', text: 'Foo Bar', count: 2)
          expect(page).to have_selector('span', text: work_package.type.name.upcase, count: 2)
          expect(page).to have_selector('span', text: work_package.status.name, count: 1)
          # Dates are being rendered in two nested spans
          expect(page).to have_selector('span', text: '01/01/2020', count: 2)
          expect(page).to have_selector('span', text: '02/01/2020', count: 2)
          expect(page).to have_selector('.work-package--quickinfo.preview-trigger', text: "##{work_package.id}", count: 2)
        end

        # Edit page again
        click_on 'Edit'

        editor.in_editor do |container,|
          expect(container).to have_selector('p', text: "###{work_package.id}")
          expect(container).to have_selector('p', text: "####{work_package.id}")
        end
      end
    end
  end
end
