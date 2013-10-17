#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

require File.expand_path('../../../../../spec_helper', __FILE__)

describe 'api/v2/planning_elements/show.api.rabl' do

  before do
    view.stub(:include_journals?).and_return(false)

    params[:format] = 'json'
  end

  let(:project) { FactoryGirl.create(:project, :id => 4711,
                                     :identifier => 'test_project',
                                     :name => 'Test Project') }
  let(:planning_element) { FactoryGirl.build(:work_package,
                                             :id => 1,
                                             :project_id => project.id,
                                             :subject => 'WorkPackage #1',
                                             :description => 'Description of this planning element',

                                             :start_date => Date.parse('2011-12-06'),
                                             :due_date   => Date.parse('2011-12-13'),

                                             :created_at => Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                                             :updated_at => Time.parse('Fri Jan 07 12:35:00 +0100 2011')) }


  describe 'with an assigned planning element' do

    before do
      assign(:planning_element, planning_element)
      render
    end

    subject {response.body}

    it 'renders a planning_element document' do
      should have_json_path('planning_element')
    end

    it 'contains an id element containing the planning element id' do
      should be_json_eql(1.to_json).at_path('planning_element/id')
    end

    it 'contains a project element containing the planning element\'s project id, identifier and name' do
      expected_json = {id: 4712, identifier: "test_project", name: "Test Project"}.to_json
      should be_json_eql(expected_json).at_path('planning_element/project')
    end



  end

  describe 'with an assigned planning element
            when requesting journals' do
    before do
      view.stub(:include_journals?).and_return(true)
    end

    let(:user) { FactoryGirl.create(:user) }
    let(:journal_1) { FactoryGirl.build(:work_package_journal,
                                        journable_id: planning_element.id,
                                        user: user) }
    let(:journal_2) { FactoryGirl.build(:work_package_journal,
                                        journable_id: planning_element.id,
                                        user: user) }

    before do
      # prevents problems related to the journal not having a user associated
      User.stub(:current).and_return(user)

      journal_1.stub(:journable).and_return planning_element
      journal_2.stub(:journable).and_return planning_element

      journal_1.stub(:get_changes).and_return({"subject"=> ["old_subject", "new_subject"]})
      journal_2.stub(:get_changes).and_return({"project_id"=> [1,2]})

      planning_element.stub(:journals).and_return [journal_1,journal_2]


      assign(:planning_element, planning_element)

      render
    end

    subject {response.body}

    it 'contains an array of journals' do
      should have_json_size(2).at_path('planning_element/journals')
    end

    it 'reports the changes' do
      expected_json = {name: "subject", old: "old_subject", new: "new_subject"}.to_json
      should be_json_eql(expected_json).at_path('planning_element/journals/0/changes/changed_data/0/change/technical')

      expected_json = {name: "project_id", old: 1, new: 2}.to_json
      should be_json_eql(expected_json).at_path('planning_element/journals/1/changes/changed_data/0/change/technical')

    end
  end
end
