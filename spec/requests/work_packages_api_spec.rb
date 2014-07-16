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

require 'spec_helper'
require 'rack/test'

describe API::V3::WorkPackages::WorkPackagesAPI do
  describe "activities" do
    let(:admin) { FactoryGirl.create(:admin) }
    let(:work_package) { FactoryGirl.create(:work_package) }
    let(:comment) { "This is a test comment!" }

    shared_examples_for "safeguarded API" do
      it { expect(response.response_code).to eq(403) }
    end

    shared_examples_for "valid activity request" do
      before { allow(User).to receive(:current).and_return(admin) }

      subject { JSON.parse(response.body) }

      it { expect(subject['_type']).to eq("Activity::Comment") }

      it { expect(subject['rawComment']).to eq(comment) }
    end

    shared_examples_for "invalid activity request" do
      before { allow(User).to receive(:current).and_return(admin) }

      it { expect(response.response_code).to eq(422) }
    end

    describe "POST /api/v3/work_packages/:id/activities" do
      shared_context "create activity" do
        before { post "/api/v3/work_packages/#{work_package.id}/activities",
                      comment: comment }
      end

      it_behaves_like "safeguarded API" do
        include_context "create activity"
      end

      it_behaves_like "valid activity request" do
        include_context "create activity"
      end

      it_behaves_like "invalid activity request" do
        before { allow_any_instance_of(WorkPackage).to receive(:save).and_return(false) }

        include_context "create activity"
      end
    end

    describe "PUT /api/v3/work_packages/:id/activities/:activityId" do
      let(:wp_journal) { FactoryGirl.build(:journal_work_package_journal) }
      let(:journal) { FactoryGirl.create(:work_package_journal,
                                         data: wp_journal,
                                         journable_id: work_package.id) }

      shared_context "edit activity" do
        before { put "/api/v3/work_packages/#{work_package.id}/activities/#{journal.id}",
                     comment: comment }
      end

      it_behaves_like "safeguarded API" do
        include_context "edit activity"
      end

      it_behaves_like "valid activity request" do
        include_context "edit activity"
      end

      it_behaves_like "invalid activity request" do
        before { allow_any_instance_of(Journal).to receive(:save).and_return(false) }

        include_context "edit activity"
      end
    end
  end
end
