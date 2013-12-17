# encoding: utf-8

require 'spec_helper'
require 'features/work_packages/work_packages_page'

describe 'Query selection' do
  let(:project) { FactoryGirl.create :project, identifier: 'test_project', is_public: false }
  let(:role) { FactoryGirl.create :role, :permissions => [:view_work_packages] }
  let(:current_user) { FactoryGirl.create :user, member_in_project: project,
                                                 member_through_role: role }

  let(:filter_name) { 'done_ratio' }
  let!(:query) do
    query = FactoryGirl.build(:query, project: project, is_public: true)
    query.filters = [Queries::WorkPackages::Filter.new(filter_name, operator: ">=", values: [10]) ]
    query.save and return query
  end

  let(:work_packages_page) { WorkPackagesPage.new(project) }

  before do
    User.stub(:current).and_return current_user
  end

  context 'when a query is selected' do
    before do
      work_packages_page.visit_index
      work_packages_page.select_query query
    end

    context 'and the work packages menu item is clicked' do
      before { work_packages_page.click_work_packages_menu_item }

      it 'clears selected queries' do
        work_packages_page.should_not have_selected_filter(filter_name)
      end
    end
  end
end
