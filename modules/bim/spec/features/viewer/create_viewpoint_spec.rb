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

require_relative '../../spec_helper'

describe 'Create viewpoint from BCF details page',
         type: :feature,
         with_config: { edition: 'bim' },
         js: true do
  let(:project) { FactoryBot.create :project, enabled_module_names: [:bim, :work_package_tracking] }
  let(:user) { FactoryBot.create :admin }

  let!(:model) do
    FactoryBot.create(:ifc_model_minimal_converted,
                      title: 'minimal',
                      project: project,
                      uploader: user)
  end

  let(:show_model_page) { Pages::IfcModels::ShowDefault.new(project) }
  let(:card_view) { ::Pages::WorkPackageCards.new(project) }
  let(:bcf_details) { ::Pages::BcfDetailsPage.new(work_package, project) }
  let(:model_tree) { ::Components::XeokitModelTree.new }

  before do
    login_as(user)
  end

  shared_examples 'can create a viewpoint from the BCF details page' do
    it do
      show_model_page.visit!
      show_model_page.finished_loading
      card_view.expect_work_package_listed work_package
      card_view.open_full_screen_by_details work_package

      # Expect no viewpoint
      bcf_details.ensure_page_loaded
      bcf_details.expect_viewpoint_count 0

      # Uncheck the second checkbox for testing
      model_tree.select_sidebar_tab 'Objects'
      model_tree.expect_checked 'minimal'
      model_tree.expand_tree

      item, checkbox = model_tree.all_checkboxes.second
      text = item.text
      checkbox.uncheck

      bcf_details.add_viewpoint
      bcf_details.expect_viewpoint_count 1

      page.driver.browser.navigate.refresh

      bcf_details.ensure_page_loaded
      bcf_details.expect_viewpoint_count 1
      bcf_details.show_current_viewpoint

      sleep 1

      # Uncheck the second checkbox for testing
      model_tree.select_sidebar_tab 'Objects'
      model_tree.expect_checked 'minimal'
      model_tree.expand_tree

      model_tree.expect_unchecked text
    end
  end

  context 'with a work package with BCF' do
    let!(:work_package) { FactoryBot.create(:work_package, project: project) }
    let!(:bcf) { FactoryBot.create :bcf_issue, work_package: work_package }

    it_behaves_like 'can create a viewpoint from the BCF details page'
  end

  context 'with a work package without BCF' do
    let!(:work_package) { FactoryBot.create(:work_package, project: project) }

    it_behaves_like 'can create a viewpoint from the BCF details page'
  end
end
