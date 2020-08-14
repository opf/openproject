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

describe 'project menu', type: :feature do
  let(:current_user) { FactoryBot.create :admin }
  let!(:project) { FactoryBot.create :valid_project, identifier: 'ponyo', name: 'Ponyo' }

  before do
    allow(User).to receive(:current).and_return current_user
    # remove filters that might be left overs from former specs
    CostQuery::Cache.reset!
  end

  ##
  # Depending on the current page the link to the cost reports was broken.
  # This seems to be due to a peculiarity of the rails routing where
  # `url_for controller: :foo` would return a link relative to the controller
  # handling the current request path if the controller was routed to via a
  # namespaced route.
  #
  # Example:
  #
  # `url_for controller: 'cost_reports'` will yield different results ...
  #
  # when on `/projects/ponyo/work_packages`: `/projects/ponyo/cost_reports` (correct)
  # when on `/projects/ponyo/work_packages/calendar`: `/work_packages/cost_reports?project_id=ponyo`
  #
  # This is only relevant for project menu entries, not global ones (`project_id` param is nil)*.
  # Meaning that you have to make sure to force the absolute URL in a project menu entry
  # by specificying the controller as e.g. '/cost_reports' instead of just 'cost_reports'.
  #
  # Refer to `engine.rb` to see where the menu entries are declared.
  #
  # * May apply to routes used with parameters in general.
  describe '#18788 (cost reports not found (404)) regression test' do
    describe 'link to project cost reports' do
      shared_examples 'it leads to the project costs reports' do
        before do
          visit current_path
        end

        it 'leads to cost reports' do
          click_on 'Time and costs'

          expect(page).to have_selector('.button--dropdown-text', text: 'Ponyo')
        end
      end

      context "when on the project's activity page" do
        let(:current_path) { '/projects/ponyo/activity' }

        it_behaves_like 'it leads to the project costs reports'
      end

      context "when on the project's calendar" do
        let(:current_path) { '/projects/ponyo/work_packages/calendar' }

        it_behaves_like 'it leads to the project costs reports'
      end
    end

    describe 'link to global cost reports' do
      shared_examples 'it leads to the cost reports' do
        before do
          visit current_path
        end

        it 'leads to cost reports' do
          # doing what no human can - click on invisible items.
          # This way, we avoid having to use selenium and by that increase stability.
          within '#more-menu', visible: false do
            click_on 'Time and costs', visible: false
          end

          # to make sure we're not seeing the project cost reports:
          expect(page).not_to have_text('Ponyo')
        end
      end

      context "when on the project's activity page" do
        let(:current_path) { '/projects/ponyo/activity' }

        it_behaves_like 'it leads to the cost reports'
      end

      context "when on the project's calendar" do
        let(:current_path) { '/projects/ponyo/work_packages/calendar' }

        it_behaves_like 'it leads to the cost reports'
      end
    end
  end
end
