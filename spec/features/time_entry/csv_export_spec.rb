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

describe 'time entry csv export', type: :feature do
  # Force project to have only the required module activated
  # This may otherwise break for non-core configurations
  let(:project) { FactoryGirl.create(:project, enabled_module_names: %w(time_tracking)) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_time_entries]) }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:project_time_entry) {
    FactoryGirl.build(:time_entry,
                      project: project,
                      work_package: work_package,
                      comments: 'la le lu')
  }
  let(:project2) { FactoryGirl.create(:project) }
  let(:work_package2) { FactoryGirl.create(:work_package, project: project2) }
  let(:project_time_entry2) {
    FactoryGirl.build(:time_entry,
                      project: project2,
                      work_package: work_package2,
                      comments: 'la le lu la le lu')
  }
  let(:current_user) {
    FactoryGirl.create(:user,
                       member_in_projects: [project, project2],
                       member_through_role: role)
  }

  include Redmine::I18n

  shared_examples_for 'csv export for time entries' do
    it 'returns a csv file with the entries' do
      expect(page.response_headers['Content-Type']).to include('text/csv')
      expect(page.response_headers['Content-Type']).to include('charset=utf-8')

      expected_header = ["#{TimeEntry.human_attribute_name(:spent_on)}," +
                         "#{TimeEntry.human_attribute_name(:user)}," +
                         "#{TimeEntry.human_attribute_name(:activity)}," +
                         "#{TimeEntry.human_attribute_name(:project)}," +
                         "#{TimeEntry.human_attribute_name(:issue)}," +
                         "#{TimeEntry.human_attribute_name(:type)}," +
                         "#{TimeEntry.human_attribute_name(:subject)}," +
                         "#{TimeEntry.human_attribute_name(:hours)}," +
                         "#{TimeEntry.human_attribute_name(:comments)}\n"]

      expected_lines = expected_header + expected_values

      page.body.each_line do |line|
        expect(expected_lines).to include(line)
      end
    end
  end

  before do
    allow(User).to receive(:current).and_return current_user
    project_time_entry.save
    project_time_entry2.save
  end

  context 'for a single project' do
    before do
      visit project_time_entries_path(project.identifier)
      click_link('CSV')
    end

    it_behaves_like 'csv export for time entries' do
      let(:expected_values) {
        ["#{format_date(project_time_entry.spent_on)},#{project_time_entry.user}," +
          "#{project_time_entry.activity},#{project_time_entry.project}," +
          "#{project_time_entry.work_package_id},#{project_time_entry.work_package.type}" +
          ",#{project_time_entry.work_package.subject},#{project_time_entry.hours}" +
          ",#{project_time_entry.comments}\n"]
      }
    end
  end

  context 'for all projects' do
    before do
      visit time_entries_path
      click_link('CSV')
    end

    it_behaves_like 'csv export for time entries' do
      let(:expected_values) {
        ["#{format_date(project_time_entry.spent_on)},#{project_time_entry.user}," +
          "#{project_time_entry.activity},#{project_time_entry.project}," +
          "#{project_time_entry.work_package_id},#{project_time_entry.work_package.type}" +
          ",#{project_time_entry.work_package.subject},#{project_time_entry.hours}" +
          ",#{project_time_entry.comments}\n",
         "#{format_date(project_time_entry2.spent_on)},#{project_time_entry2.user}," +
           "#{project_time_entry2.activity},#{project_time_entry2.project}," +
           "#{project_time_entry2.work_package_id},#{project_time_entry2.work_package.type}" +
           ",#{project_time_entry2.work_package.subject},#{project_time_entry2.hours}" +
           ",#{project_time_entry2.comments}\n"]
      }
    end
  end
end
