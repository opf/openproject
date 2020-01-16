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

describe 'Wysiwyg work package linking',
         type: :feature, js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create(:project, enabled_module_names: %w[wiki work_package_tracking]) }
  let(:work_package) { FactoryBot.create(:work_package, subject: 'Foobar', project: project) }
  let(:editor) { ::Components::WysiwygEditor.new }

  before do
    login_as(user)
  end

  describe 'creating a wiki page' do
    before do
      visit project_wiki_path(project, :wiki)
    end

    it 'can add tables without headers' do

      # single hash autocomplete
      editor.click_and_type_slowly "##{work_package.id}"
      editor.click_autocomplete work_package.subject

      expect(editor.editor_element).to have_selector('span.mention', text: "##{work_package.id}")

      # Save wiki page
      click_on 'Save'

      expect(page).to have_selector('.flash.notice')

      within('#content') do
        expect(page).to have_selector('a.issue', count: 1)
      end
    end
  end
end
