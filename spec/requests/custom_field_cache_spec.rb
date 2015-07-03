#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'support', 'custom_field_filter')
require File.join(File.dirname(__FILE__), '..', 'support', 'configuration_helper')

describe 'Custom field filter and group by caching', type: :request do
  include OpenProject::Reporting::SpecHelper::CustomFieldFilterHelper
  include OpenProject::Reporting::SpecHelper::ConfigurationHelper

  let(:project) { FactoryGirl.create(:valid_project) }
  let(:user) { FactoryGirl.create(:admin) }
  let(:custom_field) { FactoryGirl.build(:work_package_custom_field) }
  let(:custom_field2) { FactoryGirl.build(:work_package_custom_field) }

  before do
    allow(User).to receive(:current).and_return(user)

    custom_field.save!
  end

  def expect_group_by_all_to_include(custom_field)
    expect(CostQuery::GroupBy.all).to include(group_by_class_name_string(custom_field).constantize)
  end

  def expect_filter_all_to_include(custom_field)
    expect(CostQuery::Filter.all).to include(filter_class_name_string(custom_field).constantize)
  end

  def expect_group_by_all_to_not_exist(custom_field)
    # can not check for whether the element is included in CostQuery::GroupBy if it does not exist
    expect { group_by_class_name_string(custom_field).constantize }.to raise_error NameError
  end

  def expect_filter_all_to_not_exist(custom_field)
    # can not check for whether the element is included in CostQuery::GroupBy if it does not exist
    expect { group_by_class_name_string(custom_field).constantize }.to raise_error NameError
  end

  def visit_cost_reports_index
    get "projects/#{project.id}/cost_reports"
  end

  it 'removes the filter/group_by if the custom field is removed' do
    custom_field2.save!

    visit_cost_reports_index

    expect_group_by_all_to_include(custom_field)
    expect_group_by_all_to_include(custom_field2)

    expect_filter_all_to_include(custom_field)
    expect_filter_all_to_include(custom_field2)

    custom_field2.destroy

    visit_cost_reports_index

    expect_group_by_all_to_include(custom_field)
    expect_group_by_all_to_not_exist(custom_field2)

    expect_filter_all_to_include(custom_field)
    expect_filter_all_to_not_exist(custom_field2)
  end

  it 'removes the filter/group_by if the last custom field is removed' do
    visit_cost_reports_index

    expect_group_by_all_to_include(custom_field)
    expect_filter_all_to_include(custom_field)

    custom_field.destroy

    visit_cost_reports_index

    expect_group_by_all_to_not_exist(custom_field)
    expect_filter_all_to_not_exist(custom_field)
  end

  it 'allows for changing the db table between requests if no caching is done' do
    old_table_name = WorkPackageCustomField.table_name
    new_table_name = 'custom_fields_clone'
    new_id = custom_field.id + 1

    begin
      mock_cache_classes_setting_with(false)

      visit_cost_reports_index

      expect_group_by_all_to_include(custom_field)
      expect_filter_all_to_include(custom_field)

      ActiveRecord::Base.connection.execute("CREATE TABLE #{new_table_name} AS SELECT * from custom_fields;")
      ActiveRecord::Base.connection.execute("UPDATE #{new_table_name} SET id = #{new_id} WHERE id = #{custom_field.id};")
      CustomField::Translation.where(custom_field_id: custom_field.id).update_all(custom_field_id: new_id)

      WorkPackageCustomField.table_name = new_table_name

      visit_cost_reports_index

      expect_group_by_all_to_not_exist(custom_field)
      expect_filter_all_to_not_exist(custom_field)

      expect_group_by_all_to_include(new_id)
      expect_filter_all_to_include(new_id)

    ensure
      WorkPackageCustomField.table_name = old_table_name
      ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{new_table_name}")
    end
  end
end
