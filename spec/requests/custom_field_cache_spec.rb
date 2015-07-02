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

describe 'Custom field filter and group by caching', :type => :request do
  let(:project) { FactoryGirl.create(:valid_project) }
  let(:user) { FactoryGirl.create(:admin) }
  let(:custom_field) { FactoryGirl.build(:work_package_custom_field) }
  let(:custom_field2) { FactoryGirl.build(:work_package_custom_field) }

  before do
    allow(User).to receive(:current).and_return(user)

    custom_field.save!
  end

  it 'removes the filter/group_by if the custom field is removed' do
    custom_field2.save!

    get "projects/#{project.id}/cost_reports"

    expect(CostQuery::GroupBy.all).to include("CostQuery::GroupBy::CustomField#{custom_field.id}".constantize)
    expect(CostQuery::GroupBy.all).to include("CostQuery::GroupBy::CustomField#{custom_field2.id}".constantize)

    custom_field2.destroy

    get "projects/#{project.id}/cost_reports"

    expect(CostQuery::GroupBy.all).to include("CostQuery::GroupBy::CustomField#{custom_field.id}".constantize)
    # can not check for whether the element is included in CostQuery::GroupBy if it does not exist
    expect{"CostQuery::GroupBy::CustomField#{custom_field2.id}".constantize}.to raise_error NameError
  end

  it 'removes the filter/group_by if the last custom field is removed' do
    get "projects/#{project.id}/cost_reports"

    expect(CostQuery::GroupBy.all).to include("CostQuery::GroupBy::CustomField#{custom_field.id}".constantize)

    custom_field.destroy

    get "projects/#{project.id}/cost_reports"

    # can not check for whether the element is included in CostQuery::GroupBy if it does not exist
    expect{"CostQuery::GroupBy::CustomField#{custom_field.id}".constantize}.to raise_error NameError
  end
end
