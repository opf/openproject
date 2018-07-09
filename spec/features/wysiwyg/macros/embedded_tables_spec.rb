#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe 'Wysiwyg embedded work package tables',
         type: :feature, js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create(:project, enabled_module_names: %w[wiki work_package_tracking]) }
  let(:editor) { ::Components::WysiwygEditor.new }
  let!(:work_package) { FactoryBot.create(:work_package, project: project) }

  let(:modal) { ::Components::WorkPackages::TableConfigurationModal.new }
  let(:filters) { ::Components::WorkPackages::TableConfiguration::Filters.new }
  let(:columns) { ::Components::WorkPackages::Columns.new }

  before do
    login_as(user)
  end

  describe 'in wikis' do
    describe 'creating a wiki page' do
      before do
        visit project_wiki_path(project, :wiki)
      end

      it 'can add and edit an embedded table widget' do
        editor.in_editor do |container, editable|
          # strangely, we need visible: :all here
          container.find('.ck-button', visible: :all, text: 'Embed work package table').click

          modal.expect_open
          filters.expect_filter_count 1
          filters.add_filter_by('Type', 'is', work_package.type.name)

          modal.switch_to 'Columns'
          columns.assume_opened
          columns.uncheck_all save_changes: false
          columns.add 'ID', save_changes: false
          columns.add 'Subject', save_changes: false
          columns.add 'Type', save_changes: false
          columns.expect_checked 'ID'
          columns.expect_checked 'Subject'
          columns.expect_checked 'Type'

          # Save widget
          modal.save

          # Find widget, click to show toolbar
          macro = editable.find('.ck-widget.macro.-embedded-table')
          macro.click

          # Edit widget again
          page.find('.ck-balloon-panel .ck-button', visible: :all, text: 'Edit').click

          modal.expect_open
          filters.expect_filter_count 2
          modal.switch_to 'Columns'
          columns.assume_opened
          columns.expect_checked 'ID'
          columns.expect_checked 'Subject'
          columns.expect_checked 'Type'
          modal.cancel
        end

        # Save wiki page
        click_on 'Save'

        expect(page).to have_selector('.flash.notice')

        within('#content') do
          embedded_table = ::Pages::EmbeddedWorkPackagesTable.new find('.wiki-content')
          embedded_table.expect_work_package_listed work_package
        end
      end
    end
  end
end
