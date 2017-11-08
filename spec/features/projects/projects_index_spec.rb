#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'features/projects/projects_page'

describe 'Projects index page', type: :feature, js: true do
  let!(:project) { FactoryGirl.create(:project, name: 'Foo project', identifier: 'foo-project') }

  before do
    # allow(User).to receive(:current).and_return current_user
    visit projects_path
  end

  feature "restricts project visibility" do
    feature "for a anonymous user" do
      let(:public_project) { FactoryGirl.create(:project, name: 'Public project', identifier: 'public-project') }

      scenario "only public projects shall be visible" do
        expect(page).to_not have_text(project.name)
        expect(page).to have_text(private_project.name)
      end
    end

    feature "for project members" do
      pending "test visibility of all public projects"
      pending "test visibility of all projects the user is member of"
      pending "test projects are hidden that the user not member of"
      pending "test that not 'visible' CFs are not visible"
    end

    feature "for admins" do
      let(:current_user) { FactoryGirl.create(:admin) }

      pending "test that all projects are visible"
      pending "test that not 'visible' CFs are visible"
    end
  end

  context "without valid Enterprise token" do
    pending "check that no CF columns are visible"
    pending "check that no CF filters are visible"
  end

  context "with valid Enterprise token" do
    pending "check that CF columns are visible"
    pending "check that CF filters are visible"
  end

  context "with a filter set" do
    pending "it should only show the matching projects"
    pending "it should only show active filters"
  end

  context "when paginating" do
    pending "it keeps filters"
    pending "it keeps order"
  end

  context "when ordering the results" do
    pending "the results have that order"
    pending "it keeps set filters active"
  end

  context "when filter of type" do

    context "Name and identifier" do
      pending "gives results in both, name and identifier"
    end

    context "Active or archived" do
      pending "value selection defaults to 'active'"
      pending "it has three operators 'all', 'active' and 'archived'"
    end

    context "Created on" do
      context "selecting operator" do
        context "'today'" do
          pending "show projects that were created today"
        end

        context "'this week'" do
          pending "show projects that were created this week"
        end

        context "'on'" do
          pending "filters on a specific date"
        end

        context "'less than or equal' days ago" do
          pending "only shows matching projects"
        end

        context "'more than or equal' days ago" do
          pending "only shows matching projects"
        end

        context "between two dates" do
          pending "only shows matching projects"
          pending "selecting same date for from and to value shows projects of that date"
        end

      end
    end

    context "Latest activity at" do
      pending "filter uses correct data"
    end

    context "CF List" do
      pending "switching to multiselect keeps the current selection"
      pending "switching to single select keeps the first selection"
      pending "whith only one value selected next load shows single select"
      pending "whith more than one value selected next load shows multi select"
    end

    context "CF date" do

      pending "shows correct results"
    end
  end
end
