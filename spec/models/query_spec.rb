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

require 'spec_helper'

describe Query do
  describe 'available_columns'
    let(:query) { FactoryGirl.build(:query) }

    context 'with work_package_done_ratio NOT disabled' do
      it 'should include the done_ratio column' do
        query.available_columns.find {|column| column.name == :done_ratio}.should be_true
      end
    end

    context 'with work_package_done_ratio disabled' do
      before do
        Setting.stub(:work_package_done_ratio).and_return('disabled')
      end

      it 'should NOT include the done_ratio column' do
        query.available_columns.find {|column| column.name == :done_ratio}.should be_nil
      end
    end

    context 'filtering responsibles' do
      let (:project){FactoryGirl.create(:project)}
      let (:responsible_1){FactoryGirl.create(:user)}
      let (:responsible_2){FactoryGirl.create(:user)}

      before do

        wp_1 = FactoryGirl.create(:work_package, project: project, responsible_id: responsible_1.id)
        wp_2 = FactoryGirl.create(:work_package, project: project, responsible_id: responsible_2.id)
      end

      it "should return only the workpackage for the responsible given in the filter" do
        responsible_query = Query.new
        responsible_query.project = project
        #responsible_query.add_filter "responsible_id", "=", responsible_1.id

        puts WorkPackage.with_query(responsible_query).to_sql

        result = WorkPackage.with_query(responsible_query).all


        expect(result.size).to eql 1
        expect(result).to include wp_1
      end

    end
end
