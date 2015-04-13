#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'project menu', type: :feature do
  let(:current_user) { FactoryGirl.create :admin }
  let!(:project) { FactoryGirl.create :valid_project, identifier: 'ponyo' }

  before do
    allow(User).to receive(:current).and_return current_user
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
    describe 'link to cost reports' do
      context "when on the project's activity page" do
        before do
          visit '/projects/ponyo/activity'
        end

        it 'shows the correct link to cost reports: /projects/ponyo/cost_reports' do
          a = find_link 'Cost Reports'

          expect(a).to be_present
          expect(a[:href]).to match %r{/projects/ponyo/cost_reports$}
        end
      end

      context "when on the project's calendar" do
        before do
          visit '/projects/ponyo/work_packages/calendar'
        end

        it 'shows the correct link to cost reports: /projects/ponyo/cost_reports' do
          a = find_link 'Cost Reports'

          expect(a).to be_present
          expect(a[:href]).to match %r{/projects/ponyo/cost_reports$}
        end
      end
    end
  end
end
