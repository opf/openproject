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

  subject {response.body}

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

    let(:custom_field) do
      FactoryGirl.create :issue_custom_field,
        :name => "Belag",
        :field_format => "text",
        :projects => [planning_element.project],
        :types => [(Type.find_by_name("None") || FactoryGirl.create(:type_standard))]
    end

    before do
      custom_value = CustomValue.new(
        :custom_field => custom_field,
        :value => "Wurst")
      planning_element.custom_values << custom_value

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

    it 'contains an name element containing the planning subject' do
      should be_json_eql("WorkPackage #1".to_json).at_path('planning_element/subject')
    end

    it 'contains an description element containing the planning element description' do
      should be_json_eql("Description of this planning element".to_json).at_path('planning_element/description')
    end

    it 'contains an start_date element containing the planning element start_date in YYYY-MM-DD' do
      should be_json_eql('2011-12-06'.to_json).at_path('planning_element/start_date')
    end

    it 'contains an due_date element containing the planning element due_date in YYYY-MM-DD' do
      should be_json_eql('2011-12-13'.to_json).at_path('planning_element/due_date')
    end

    it 'contains a created_at element containing the planning element created_at in UTC in ISO 8601' do
      should be_json_eql('2011-01-06T11:35:00Z'.to_json).at_path('planning_element/created_at')
    end

    it 'contains an updated_at element containing the planning element updated_at in UTC in ISO 8601' do
      should be_json_eql('2011-01-07T11:35:00Z'.to_json).at_path('planning_element/updated_at')
    end

    it 'renders the custom field values' do
      should have_json_path('planning_element/custom_fields')

      expected_json = {name: custom_field.name, value: "Wurst"}.to_json
      should be_json_eql(expected_json).at_path('planning_element/custom_fields/0')
    end
  end

  describe 'with a planning element having a parent' do
    let(:project) { FactoryGirl.create(:project) }

    let(:parent_element)   { FactoryGirl.create(:work_package,
                                                :id         => 1337,
                                                :subject       => 'Parent Element',
                                                :project_id => project.id) }
    let(:planning_element) {  FactoryGirl.build(:work_package,
                                                :parent_id  => parent_element.id,
                                                :project_id => project.id) }

    before do
      assign(:planning_element, planning_element)
      render
    end

    it 'renders a parent node containing the parent\'s id and subject' do
      expected_json = {id: 1337, subject: "Parent Element"}.to_json
      response.should be_json_eql(expected_json).at_path('planning_element/parent')
    end
  end

  describe 'with a planning element having children' do
    let(:project) { FactoryGirl.create(:project) }
    let(:planning_element) { FactoryGirl.create(:work_package,
                                                :subject => "Parent Package",
                                                :id => 1338,
                                                :project => project) }

    before do
      FactoryGirl.create(:work_package,
                         :project_id => project.id,
                         :parent_id  => planning_element.id,
                         :id         => 1339,
                         :subject    => 'Child #1')
      FactoryGirl.create(:work_package,
                         :project_id => project.id,
                         :parent_id  => planning_element.id,
                         :id         => 1340,
                         :subject    => 'Child #2')

      planning_element.reload

      assign(:planning_element, planning_element)
      render
    end

    it 'renders a children node containing child nodes for each child planning element' do
      should have_json_size(2).at_path('planning_element/children')
    end

    it 'each child node has an id and subject attribute' do
      should be_json_eql({id: 1339, subject: "Child #1"}.to_json).at_path('planning_element/children/0')
      should be_json_eql({id: 1340, subject: "Child #2"}.to_json).at_path('planning_element/children/1')
    end
  end

  describe 'with a planning element having a responsible' do
    let(:responsible)      { FactoryGirl.create(:user,
                                                :id => 1341,
                                                :firstname => 'Paul',
                                                :lastname => 'McCartney') }
    let(:planning_element) { FactoryGirl.build(:work_package,
                                               :responsible_id => responsible.id) }

    before do
      assign(:planning_element, planning_element)
      render
    end

    it 'renders a responsible node containing the responsible\'s id and name' do

      response.should be_json_eql({name: "Paul McCartney"}.to_json).at_path('planning_element/responsible')
    end
  end

  describe "a destroyed planning element" do
    let(:planning_element) { FactoryGirl.create(:work_package) }

    before do
      planning_element.destroy

      assign(:planning_element, planning_element)
      render
    end

    it 'renders a planning_element node having destroyed=true' do
      response.should be_json_eql(true.to_json).at_path('planning_element/destroyed')
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
      should be_json_eql(expected_json).at_path('planning_element/journals/0/changes/0/technical')

      expected_json = {name: "project_id", old: 1, new: 2}.to_json
      should be_json_eql(expected_json).at_path('planning_element/journals/1/changes/0/technical')

    end
  end
end
