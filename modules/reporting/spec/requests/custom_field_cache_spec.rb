#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"
require File.join(File.dirname(__FILE__), "..", "support", "custom_field_filter")
require File.join(File.dirname(__FILE__), "..", "support", "configuration_helper")

RSpec.describe "Custom field filter and group by caching" do
  include OpenProject::Reporting::SpecHelper::CustomFieldFilterHelper
  include OpenProject::Reporting::SpecHelper::ConfigurationHelper

  let(:project) { create(:valid_project) }
  let(:user) { create(:admin) }
  let(:custom_field) { build(:work_package_custom_field) }
  let(:custom_field2) { build(:work_package_custom_field) }

  before do
    allow(User).to receive(:current).and_return(user)

    custom_field.save!
  end

  after do
    CostQuery::Cache.reset!
  end

  def expect_group_by_all_to_include(custom_field)
    expect(CostQuery::GroupBy.all).to include(group_by_class_name_string(custom_field).constantize)
  end

  def expect_filter_all_to_include(custom_field)
    expect(CostQuery::Filter.all).to include(filter_class_name_string(custom_field).constantize)
  end

  def expect_group_by_all_to_not_exist(custom_field)
    # can not check for whether the element is included in CostQuery::GroupBy.all if it does not exist
    expect { group_by_class_name_string(custom_field).constantize }.to raise_error NameError
  end

  def expect_filter_all_to_not_exist(custom_field)
    # can not check for whether the element is included in CostQuery::Filter.all if it does not exist
    expect { filter_class_name_string(custom_field).constantize }.to raise_error NameError
  end

  def visit_cost_reports_index
    header "Content-Type", "text/html"
    header "X-Requested-With", "XMLHttpRequest"
    get "/projects/#{project.id}/cost_reports"
  end

  it "removes the filter/group_by if the custom field is removed" do
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

  it "removes the filter/group_by if the last custom field is removed" do
    visit_cost_reports_index

    expect_group_by_all_to_include(custom_field)
    expect_filter_all_to_include(custom_field)

    custom_field.destroy

    visit_cost_reports_index

    expect_group_by_all_to_not_exist(custom_field)
    expect_filter_all_to_not_exist(custom_field)
  end

  it "allows for changing the db entries directly via SQL between requests " \
     "if no caching is done (this could also mean switching dbs)" do
    new_label = "our new label"
    mock_cache_classes_setting_with(false)

    visit_cost_reports_index

    expect_group_by_all_to_include(custom_field)
    expect_filter_all_to_include(custom_field)

    CustomField.where(id: custom_field.id)
               .update_all(name: new_label)

    visit_cost_reports_index

    expect_group_by_all_to_include(custom_field)
    expect_filter_all_to_include(custom_field)

    expect(group_by_class_name_string(custom_field).constantize.label).to eql(new_label)
    expect(filter_class_name_string(custom_field).constantize.label).to eql(new_label)
  end
end
