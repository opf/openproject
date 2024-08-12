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
  let(:work_package_1) do
    create(:work_package,
           subject: "Can't print recipes",
           project:)
  end

  let(:work_package_2) do
    create(:work_package,
           subject: "Error when updating a recipe",
           project:)
  end

  let(:work_package_3) do
    create(:work_package,
           subject: "Lorem ipsum",
           project:)
  end

  before do
    member

    allow(User).to receive(:current).and_return user

    work_package_1
    work_package_2
    work_package_3
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
      let(:expected_values) { [work_package_1, work_package_2] }

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
      let(:expected_values) { work_package_1 }

      before do
        get :index,
            params: {
              project_id: project.id,
              q: work_package_1.id
            },
            format: :json
      end

      it_behaves_like "successful response"

      it_behaves_like "contains expected values"
    end

    describe "returns work package for given id" do
      # this relies on all expected work packages to have ids that contain the given string
      # we do not want to have work_package_3 so we take it's id + 1 to create a string
      # we are sure to not be part of work_package_3's id.
      let(:ids) do
        taken_ids = WorkPackage.pluck(:id).map(&:to_s)

        id = work_package_3.id + 1

        while taken_ids.include?(id.to_s) || work_package_3.id.to_s.include?(id.to_s)
          id = id + 1
        end

        id.to_s
      end

      let!(:expected_values) do
        expected = [work_package_1, work_package_2]

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

      context "uniq" do
        let(:assigned) { assigns(:work_packages) }

        subject { assigned.size }

        it { is_expected.to eq(assigned.uniq.size) }
      end
    end

    describe "returns work package for given id" do
      render_views
      let(:work_package_4) do
        create(:work_package,
               subject: "<script>alert('danger!');</script>",
               project:)
      end
      let(:expected_values) { work_package_4 }

      before do
        get :index,
            params: {
              project_id: project.id,
              q: work_package_4.id
            },
            format: :json
      end

      it_behaves_like "successful response"
      it_behaves_like "contains expected values"

      it "escapes html" do
        expect(response.body).not_to include "<script>"
      end
    end

    describe "in different projects" do
      let(:project_2) do
        create(:project,
               parent: project)
      end
      let(:expected_values) { work_package_4 }
      let(:member_2) do
        create(:member,
               project: project_2,
               principal: user,
               roles: [role])
      end
      let(:work_package_4) do
        create(:work_package,
               subject: "Foo Bar Baz",
               project: project_2)
      end

      before do
        member_2

        work_package_4

        get :index,
            params: {
              project_id: project.id,
              q: work_package_4.id
            },
            format: :json
      end

      it_behaves_like "successful response"

      it_behaves_like "contains expected values"
    end
  end
end
