# frozen_string_literal: true

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

RSpec.describe WorkPackages::AutoCompletesController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) do
    create(:project_role,
           permissions: [:view_work_packages])
  end
  let(:member) do
    create(:member,
           project:,
           principal: user,
           roles: [role])
  end
  let(:work_package1) do
    create(:work_package,
           subject: "Can't print recipes",
           project:)
  end

  let(:work_package2) do
    create(:work_package,
           subject: "Error when updating a recipe",
           project:)
  end

  let(:work_package3) do
    create(:work_package,
           subject: "Lorem ipsum",
           project:)
  end

  before do
    member

    allow(User).to receive(:current).and_return user

    work_package1
    work_package2
    work_package3
  end

  shared_examples_for "successful response" do
    subject { response }

    it { is_expected.to be_successful }
  end

  shared_examples_for "contains expected values" do
    subject { assigns(:work_packages) }

    it { is_expected.to include(*expected_values) }
  end

  describe "#work_packages" do
    describe "search is case insensitive" do
      let(:expected_values) { [work_package1, work_package2] }

      before do
        get :index,
            params: {
              project_id: project.id,
              q: "ReCiPe"
            },
            format: :json
      end

      it_behaves_like "successful response"

      it_behaves_like "contains expected values"
    end

    describe "returns work package for given id" do
      let(:expected_values) { work_package1 }

      before do
        get :index,
            params: {
              project_id: project.id,
              q: work_package1.id
            },
            format: :json
      end

      it_behaves_like "successful response"

      it_behaves_like "contains expected values"
    end

    describe "returns work package for given ids" do
      # this relies on all expected work packages to have ids that contain the given string
      # we do not want to have work_package3 so we take its id + 1 to create a string
      # we are sure to not be part of work_package3's id.
      let(:ids) do
        taken_ids = WorkPackage.pluck(:id).map(&:to_s)

        id = work_package3.id + 1

        while taken_ids.include?(id.to_s) || work_package3.id.to_s.include?(id.to_s)
          id = id + 1
        end

        id.to_s
      end

      let!(:expected_values) do
        expected = [work_package1, work_package2]

        WorkPackage.pluck(:id)

        expected_return = []
        expected.each do |wp|
          new_id = wp.id.to_s + ids
          WorkPackage.where(id: wp.id).update_all(id: new_id)
          expected_return << WorkPackage.find(new_id)
        end

        expected_return
      end

      before do
        get :index,
            params: {
              project_id: project.id,
              q: ids
            },
            format: :json
      end

      it_behaves_like "successful response"

      it_behaves_like "contains expected values"

      context "when unique" do
        let(:assigned) { assigns(:work_packages) }

        subject { assigned.size }

        it { is_expected.to eq(assigned.uniq.size) }
      end
    end

    describe "returns work package for given id, escaping html" do
      render_views
      let(:work_package3) do
        create(:work_package,
               subject: "<script>alert('danger!');</script>",
               project:)
      end
      let(:expected_values) { work_package3 }

      before do
        get :index,
            params: {
              project_id: project.id,
              q: work_package3.id
            },
            format: :json
      end

      it_behaves_like "successful response"
      it_behaves_like "contains expected values"

      it "escapes html" do
        expect(response.body).not_to include "<script>"
      end
    end

    describe "displayId JSON contract" do
      # The CKEditor mention plugin reads `displayId` (camelCase, stringified)
      # off each entry to insert `#PROJ-7` or `#1234` into the editor and to
      # build the mention's link URL. The contract must hold in both modes
      # so the frontend doesn't have to branch on identifier shape.
      render_views

      let(:expected_values) { work_package1 }
      let(:json) { response.parsed_body }
      let(:entry) { json.find { |e| e["id"] == work_package1.id } }

      before do
        get :index,
            params: { project_id: project.id, q: work_package1.id },
            format: :json
      end

      context "in classic mode",
              with_settings: { work_packages_identifier: "classic" } do
        it "exposes displayId as the stringified numeric id" do
          expect(entry).to include("displayId" => work_package1.id.to_s)
        end
      end

      context "in semantic mode",
              with_settings: { work_packages_identifier: "semantic" } do
        let(:project) { create(:project, identifier: "MENTPROJ") }

        before { work_package1.allocate_and_register_semantic_id }

        it "exposes displayId as the semantic identifier string" do
          expect(entry["displayId"]).to start_with("MENTPROJ-")
          expect(entry["displayId"]).to be_a(String)
        end
      end
    end

    describe "in different projects" do
      let(:project2) do
        create(:project,
               parent: project)
      end
      let(:expected_values) { work_package3 }
      let(:member2) do
        create(:member,
               project: project2,
               principal: user,
               roles: [role])
      end
      let(:work_package3) do
        create(:work_package,
               subject: "Foo Bar Baz",
               project: project2)
      end

      before do
        member2

        work_package3

        get :index,
            params: {
              project_id: project.id,
              q: work_package3.id
            },
            format: :json
      end

      it_behaves_like "successful response"

      it_behaves_like "contains expected values"
    end
  end
end
