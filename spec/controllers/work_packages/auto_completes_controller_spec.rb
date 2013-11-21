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

describe WorkPackages::AutoCompletesController do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role,
                                  permissions: [:view_work_packages]) }
  let(:member) { FactoryGirl.create(:member,
                                    project: project,
                                    principal: user,
                                    roles: [role]) }
  let(:work_package_1) { FactoryGirl.create(:work_package,
                                            id: 21,
                                            subject: "Can't print recipes",
                                            project: project) }
  let(:work_package_2) { FactoryGirl.create(:work_package,
                                            id: 2101,
                                            subject: "Error 281 when updating a recipe",
                                            project: project) }
  let(:work_package_3) { FactoryGirl.create(:work_package,
                                            id: 2102,
                                            project: project) }

  before do
    member

    User.stub(:current).and_return user

    work_package_1
    work_package_2
    work_package_3
  end

  shared_examples_for "successful response" do
    subject { response }

    it { should be_success }
  end

  shared_examples_for "contains expected values" do
    subject { assigns(:work_packages) }

    it { should include(*expected_values) }
  end

  describe :work_packages do
    describe "search is case insensitive" do
      let(:expected_values) { [work_package_1, work_package_2] }

      before { get :index,
                   project_id: project.id,
                   q: 'ReCiPe' }

      it_behaves_like "successful response"

      it_behaves_like "contains expected values"
    end

    describe "returns work package for given id" do
      let(:expected_values) { work_package_1 }

      before { get :index,
                   project_id: project.id,
                   q: work_package_1.id }

      it_behaves_like "successful response"

      it_behaves_like "contains expected values"
    end

    describe "returns work package for given id" do
      let(:expected_values) { [work_package_1, work_package_2, work_package_3] }
      let(:ids) { '21' }

      before { get :index,
                   project_id: project.id,
                   q: ids }

      it_behaves_like  "successful response"

      it_behaves_like "contains expected values"

      context :uniq do
        let(:assigned) { assigns(:work_packages) }

        subject { assigned.size }

        it { should eq(assigned.uniq.size) }
      end
    end

    describe :cross_project_work_package_relations do
      let(:project_2) { FactoryGirl.create(:project,
                                           parent: project) }
      let(:member_2) { FactoryGirl.create(:member,
                                          project: project_2,
                                          principal: user,
                                          roles: [role]) }
      let(:work_package_4) { FactoryGirl.create(:work_package,
                                                project: project_2) }

      before do 
        member_2

        work_package_4
      end

      context "with scope all and cross project relations" do
        let(:expected_values) { work_package_4 }

        before do
          Setting.stub(:cross_project_work_package_relations?).and_return(true)

          get :index,
              project_id: project.id,
              q: work_package_4.id,
              scope: 'all'
        end

        it_behaves_like  "successful response"

        it_behaves_like "contains expected values"
      end

      context "with scope all but w/o cross project relations" do
        before do
          Setting.stub(:cross_project_work_package_relations?).and_return(false)
          
          get :index,
              project_id: project.id,
              q: work_package_4.id,
              scope: 'all'
        end

        it_behaves_like  "successful response"

        subject { assigns(:work_packages) }

        it { should eq([]) }
      end
    end
  end
end
