#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
require_relative 'shared_context'
require_relative 'overview_page'

RSpec.describe 'Edit project custom fields on project overview page', :js, :with_cuprite do
  include_context 'with seeded projects, members and project custom fields'

  let(:overview_page) { OverviewPage.new(project) }

  before do
    login_as admin
  end

  describe 'with enabled project attributes feature', with_flag: { project_attributes: true } do
    describe 'with sufficient permissions' do
      describe 'enables editing of project custom field values via dialog' do
        it 'opens a dialog showing inputs for project custom fields of a specific section' do
          overview_page.visit_page

          overview_page.within_async_loaded_sidebar do
            overview_page.within_custom_field_section_container(section_for_input_fields) do
              page.find("[data-qa-selector='project-custom-field-section-edit-button']").click
            end
          end

          expect(page).to have_css("modal-dialog#edit-project-attributes-dialog-#{section_for_input_fields.id}")
        end
      end
    end
  end
end
