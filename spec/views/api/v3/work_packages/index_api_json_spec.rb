#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe 'api/v3/work_packages/index.api.rabl' do
  before do
    params[:format] = 'json'

    assign(:work_packages, work_packages)
    assign(:column_names, column_names)
    assign(:custom_field_column_names, custom_field_column_names)
    render
  end

  subject { response.body }

  describe 'with no work packages available' do
    let(:work_packages) { [] }
    let(:column_names) { [] }
    let(:custom_field_column_names) { [] }

    it { should have_json_path('work_packages') }
    it { should have_json_size(0).at_path('work_packages') }
  end

  describe 'with 3 work packages but no columns' do
    let(:work_packages) { [
      FactoryGirl.build(:work_package),
      FactoryGirl.build(:work_package),
      FactoryGirl.build(:work_package)
    ] }
    let(:column_names)       { [] }
    let(:custom_field_column_names) { [] }

    it { should have_json_path('work_packages') }
    it { should have_json_size(3).at_path('work_packages') }

    it { should have_json_type(Object).at_path('work_packages/2') }
  end

  describe 'with 2 work packages and columns' do
    let(:work_packages) { [
      FactoryGirl.build(:work_package),
      FactoryGirl.build(:work_package)
    ] }
    let(:column_names)       { %w(subject description due_date) }
    let(:custom_field_column_names) { [] }

    it { should have_json_path('work_packages') }
    it { should have_json_size(2).at_path('work_packages') }

    it { should have_json_type(Object).at_path('work_packages/1') }
    it { should have_json_path('work_packages/1/subject')         }
    it { should have_json_path('work_packages/1/description')     }
    it { should have_json_path('work_packages/1/due_date')        }
  end

  describe 'with project column' do
    let(:work_packages) { [FactoryGirl.build(:work_package)] }
    let(:column_names) { %w(subject project) }
    let(:custom_field_column_names) { [] }

    it { should have_json_path('work_packages/0/project') }
    it { should have_json_path('work_packages/0/project/identifier') }
  end
end
