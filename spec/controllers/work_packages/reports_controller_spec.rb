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

RSpec.describe WorkPackages::ReportsController do
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
           id: 21,
           subject: "Can't print recipes",
           project:)
  end
  let(:work_package_2) do
    create(:work_package,
           id: 2101,
           subject: "Error 281 when updating a recipe",
           project:)
  end
  let(:work_package_3) do
    create(:work_package,
           id: 2102,
           project:)
  end

  before do
    member

    allow(User).to receive(:current).and_return user

    work_package_1
    work_package_2
    work_package_3
  end

  describe "#report" do
    describe "w/o details" do
      before do
        get :report,
            params: { project_id: project.id }
      end

      subject { response }

      it { is_expected.to be_successful }

      it { is_expected.to render_template("report") }

      it { assigns :work_packages_by_type }

      it { assigns :work_packages_by_version }

      it { assigns :work_packages_by_category }

      it { assigns :work_packages_by_assigned_to }

      it { assigns :work_packages_by_responsible }

      it { assigns :work_packages_by_author }

      it { assigns :work_packages_by_subproject }
    end

    describe "with details" do
      shared_examples_for "details view" do
        before do
          get :report_details,
              params: { project_id: project.id, detail: }
        end

        subject { response }

        it { is_expected.to be_successful }

        it { is_expected.to render_template("report_details") }

        it { assigns :field }

        it { assigns :rows }

        it { assigns :data }

        it { assigns :report_title }
      end

      describe "#type" do
        let(:detail) { "type" }

        it_behaves_like "details view"
      end

      describe "#version" do
        let(:detail) { "version" }

        it_behaves_like "details view"
      end

      describe "#priority" do
        let(:detail) { "priority" }

        it_behaves_like "details view"
      end

      describe "#category" do
        let(:detail) { "category" }

        it_behaves_like "details view"
      end

      describe "#assigned_to" do
        let(:detail) { "assigned_to" }

        it_behaves_like "details view"
      end

      describe "#responsible" do
        let(:detail) { "responsible" }

        it_behaves_like "details view"
      end

      describe "#author" do
        let(:detail) { "author" }

        it_behaves_like "details view"
      end

      describe "#subproject" do
        let(:detail) { "subproject" }

        it_behaves_like "details view"
      end

      context "invalid detail" do
        before do
          get :report_details,
              params: { project_id: project.id, detail: "invalid" }
        end

        subject { response }

        it { is_expected.to be_redirect }

        it { is_expected.to redirect_to(report_project_work_packages_path(project.identifier)) }
      end
    end
  end
end
