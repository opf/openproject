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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe API::V3::WorkPackages::WorkPackagesAPI do
  let(:admin) { FactoryGirl.create(:admin) }

  describe "available responsibles" do
    let(:work_package) { FactoryGirl.build_stubbed(:work_package) }

    before { allow(WorkPackage).to receive(:find).and_return(work_package) }

    shared_context "request available responsibles" do
      before { get "/api/v3/work_packages/#{work_package.id}/available_responsibles" }
    end

    it_behaves_like "safeguarded API" do
      include_context "request available responsibles"
    end

    describe "response" do
      before { allow(User).to receive(:current).and_return(admin) }

      shared_examples_for "returns available responsibles" do
        include_context "request available responsibles"

        subject { JSON.parse(response.body) }

        it { expect(subject).to have_key("_embedded") }

        it { expect(subject["_embedded"]).to have_key("availableResponsibles") }

        it { expect(subject["_embedded"]["availableResponsibles"].count).to eq(available_responsible_count) }
      end

      describe "users" do
        let(:user) { FactoryGirl.build_stubbed(:user) }
        let(:user2) { FactoryGirl.build_stubbed(:user) }

        context "single user" do
          before do
            allow(work_package.project).to receive(:possible_responsibles).and_return([user])

            allow(user).to receive(:created_on).and_return(user.created_at)
            allow(user).to receive(:updated_on).and_return(user.created_at)
          end

          it_behaves_like "returns available responsibles" do
            let(:available_responsible_count) { 1 }
          end
        end

        context "multiple users" do
          before do
            allow(work_package.project).to receive(:possible_responsibles).and_return([user, user2])

            allow(user).to receive(:created_on).and_return(user.created_at)
            allow(user).to receive(:updated_on).and_return(user.created_at)

            allow(user2).to receive(:created_on).and_return(user.created_at)
            allow(user2).to receive(:updated_on).and_return(user.created_at)
          end

          it_behaves_like "returns available responsibles" do
            let(:available_responsible_count) { 2 }
          end
        end
      end

      describe "groups" do
        let(:group) { FactoryGirl.create(:group) }
        let(:work_package) { FactoryGirl.create(:work_package) }

        before { allow(WorkPackage).to receive(:find).and_return(work_package) }

        context "with work_package_group_assignment" do
          before do
            allow(Setting).to receive(:work_package_group_assignment?).and_return(true)
            work_package.project.add_member! group, FactoryGirl.create(:role)
          end

          it_behaves_like "returns available responsibles" do
            let(:available_responsible_count) { 0 }
          end
        end
      end
    end
  end
end
