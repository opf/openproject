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

RSpec.describe WorkPackages::BulkController, with_settings: { journal_aggregation_time_minutes: 0 } do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:custom_field_value) { "125" }
  let(:custom_field1) do
    create(:work_package_custom_field,
           field_format: "string",
           is_for_all: true)
  end
  let(:custom_field2) { create(:work_package_custom_field) }
  let(:custom_field_user) { create(:issue_custom_field, :user) }
  let(:status) { create(:status) }
  let(:type) do
    create(:type_standard,
           custom_fields: [custom_field1, custom_field2, custom_field_user])
  end
  let(:project1) do
    create(:project,
           types: [type],
           work_package_custom_fields: [custom_field2])
  end
  let(:project2) do
    create(:project,
           types: [type])
  end
  let(:role) do
    create(:project_role,
           permissions: %i[edit_work_packages
                           view_work_packages
                           manage_subtasks
                           assign_versions
                           work_package_assigned])
  end
  let(:member1_p1) do
    create(:member,
           project: project1,
           principal: user,
           roles: [role])
  end
  let(:member2_p1) do
    create(:member,
           project: project1,
           principal: user2,
           roles: [role])
  end
  let(:member1_p2) do
    create(:member,
           project: project2,
           principal: user,
           roles: [role])
  end
  let(:work_package1) do
    create(:work_package,
           author: user,
           assigned_to: user,
           responsible: user2,
           type:,
           status:,
           custom_field_values: { custom_field1.id => custom_field_value },
           project: project1)
  end
  let(:work_package2) do
    create(:work_package,
           author: user,
           assigned_to: user,
           responsible: user2,
           type:,
           status:,
           custom_field_values: { custom_field1.id => custom_field_value },
           project: project1)
  end
  let(:work_package3) do
    create(:work_package,
           author: user,
           type:,
           status:,
           custom_field_values: { custom_field1.id => custom_field_value },
           project: project2)
  end

  let(:stub_work_package) { build_stubbed(:work_package) }

  before do
    custom_field1
    member1_p1
    member2_p1

    allow(User).to receive(:current).and_return user
  end

  describe "#edit" do
    shared_examples_for "response" do
      subject { response }

      it { is_expected.to be_successful }

      it { is_expected.to render_template("edit") }
    end

    context "same project" do
      before { get :edit, params: { ids: [work_package1.id, work_package2.id] } }

      it_behaves_like "response"

      describe "#view" do
        render_views

        subject { response }

        describe "#parent" do
          it { assert_select "input", attributes: { name: "work_package[parent_id]" } }
        end

        context "custom_field" do
          describe "#type" do
            it { assert_select "input", attributes: { name: "work_package[custom_field_values][#{custom_field1.id}]" } }
          end

          describe "#project" do
            it { assert_select "select", attributes: { name: "work_package[custom_field_values][#{custom_field2.id}]" } }
          end

          describe "#user" do
            it { assert_select "select", attributes: { name: "work_package[custom_field_values][#{custom_field_user.id}]" } }
          end
        end
      end
    end

    context "different projects" do
      before do
        member1_p2

        get :edit, params: { ids: [work_package1.id, work_package2.id, work_package3.id] }
      end

      it_behaves_like "response"

      describe "#view" do
        render_views

        subject { response }

        describe "#parent" do
          it { assert_select "input", { attributes: { name: "work_package[parent_id]" } }, false }
        end

        context "custom_field" do
          describe "#type" do
            it { assert_select "input", attributes: { name: "work_package[custom_field_values][#{custom_field1.id}]" } }
          end

          describe "#project" do
            it {
              assert_select "select", { attributes: { name: "work_package[custom_field_values][#{custom_field2.id}]" } }, false
            }
          end
        end
      end
    end
  end

  describe "#update" do
    let(:work_package_ids) { [work_package1.id, work_package2.id] }
    let(:work_packages) { WorkPackage.where(id: work_package_ids) }
    let(:priority) { create(:priority_immediate) }
    let(:group_id) { "" }
    let(:responsible_id) { "" }

    describe "#redirect" do
      context "in host" do
        let(:url) { "/work_packages" }

        before { put :update, params: { ids: work_package_ids, back_url: url } }

        subject { response }

        it { is_expected.to be_redirect }

        it { is_expected.to redirect_to(url) }
      end

      context "of host" do
        let(:url) { "http://google.com" }

        before { put :update, params: { ids: work_package_ids, back_url: url } }

        subject { response }

        it { is_expected.to be_redirect }

        it { is_expected.to redirect_to(project_work_packages_path(project1)) }
      end
    end

    shared_context "update_request" do
      before do
        put :update,
            params: {
              ids: work_package_ids,
              work_package: { priority_id: priority.id,
                              assigned_to_id: group_id,
                              responsible_id:,
                              send_notification:,
                              journal_notes: "Bulk editing" }
            }
      end
    end

    shared_examples_for "delivered" do
      subject { ActionMailer::Base.deliveries.size }

      it { delivery_size }
    end

    context "with notification" do
      let(:send_notification) { "1" }
      let(:delivery_size) { 2 }

      shared_examples_for "updated work package" do
        describe "#priority" do
          subject { WorkPackage.where(priority_id: priority.id).map(&:id) }

          it { is_expected.to match_array(work_package_ids) }
        end

        describe "#custom_fields" do
          let(:result) { [custom_field_value] }

          subject do
            WorkPackage.where(id: work_package_ids)
              .map { |w| w.custom_value_for(custom_field1.id).value }
              .uniq
          end

          it { is_expected.to match_array(result) }
        end

        describe "#journal" do
          describe "#notes" do
            let(:result) { ["Bulk editing"] }

            subject do
              WorkPackage.where(id: work_package_ids)
                .map { |w| w.last_journal.notes }
                .uniq
            end

            it { is_expected.to match_array(result) }
          end

          describe "#details" do
            let(:result) { [1] }

            subject do
              WorkPackage.where(id: work_package_ids)
                .map { |w| w.last_journal.details.size }
                .uniq
            end

            it { is_expected.to match_array(result) }
          end
        end
      end

      context "single project" do
        include_context "update_request"

        it { expect(response.response_code).to eq(302) }

        it_behaves_like "delivered"

        it_behaves_like "updated work package"
      end

      context "different projects" do
        let(:work_package_ids) { [work_package1.id, work_package2.id, work_package3.id] }

        context "with permission" do
          before { member1_p2 }

          include_context "update_request"

          it { expect(response.response_code).to eq(302) }

          it_behaves_like "delivered"

          it_behaves_like "updated work package"
        end

        context "w/o permission" do
          include_context "update_request"

          it { expect(response.response_code).to eq(403) }

          describe "#journal" do
            subject { Journal.for_work_package.count }

            it { is_expected.to eq(work_package_ids.count) }
          end
        end
      end

      describe "#properties" do
        describe "#groups" do
          let(:group) { create(:group) }
          let(:group_id) { group.id }

          subject { work_packages.map(&:assigned_to_id).uniq }

          context "allowed" do
            let!(:member_group_p1) do
              create(:member,
                     project: project1,
                     principal: group,
                     roles: [role])
            end

            include_context "update_request"
            it "does succeed" do
              expect(flash[:error]).to be_nil
              expect(subject).to contain_exactly(group.id)
            end
          end

          context "not allowed" do
            render_views

            include_context "update_request"

            it "does not succeed" do
              expect(flash[:error])
                .to include(I18n.t(:"work_packages.bulk.none_could_be_saved",
                                   total: 2))
              expect(subject).to contain_exactly(user.id)
            end
          end
        end

        describe "#responsible" do
          let(:responsible_id) { user.id }

          include_context "update_request"

          subject { work_packages.map(&:responsible_id).uniq }

          it { is_expected.to contain_exactly(responsible_id) }
        end

        describe "#status" do
          let(:closed_status) { create(:closed_status) }
          let(:workflow) do
            create(:workflow,
                   role:,
                   type_id: type.id,
                   old_status: status,
                   new_status: closed_status)
          end

          before do
            workflow

            put :update,
                params: {
                  ids: work_package_ids,
                  work_package: { status_id: closed_status.id }
                }
          end

          subject { work_packages.map(&:status_id).uniq }

          it { is_expected.to contain_exactly(closed_status.id) }
        end

        describe "#parent" do
          let(:parent) do
            create(:work_package,
                   author: user,
                   project: project1)
          end

          before do
            put :update,
                params: {
                  ids: work_package_ids,
                  work_package: { parent_id: parent.id }
                }
          end

          subject { work_packages.map(&:parent_id).uniq }

          it { is_expected.to contain_exactly(parent.id) }
        end

        describe "#custom_fields" do
          let(:result) { "777" }

          before do
            put :update,
                params: {
                  ids: work_package_ids,
                  work_package: {
                    custom_field_values: { custom_field1.id.to_s => result }
                  }
                }
          end

          subject do
            work_packages.map { |w| w.custom_value_for(custom_field1.id).value }
                         .uniq
          end

          it { is_expected.to contain_exactly(result) }
        end

        describe "#unassign" do
          before do
            put :update,
                params: {
                  ids: work_package_ids,
                  work_package: { assigned_to_id: "none" }
                }
          end

          subject { work_packages.map(&:assigned_to_id).uniq }

          it { is_expected.to contain_exactly(nil) }
        end

        describe "#delete_responsible" do
          before do
            put :update,
                params: {
                  ids: work_package_ids,
                  work_package: { responsible_id: "none" }
                }
          end

          subject { work_packages.map(&:responsible_id).uniq }

          it { is_expected.to contain_exactly(nil) }
        end

        describe "#version" do
          describe "set version_id attribute to some version" do
            let(:version) do
              create(:version,
                     status: "open",
                     sharing: "tree",
                     project: subproject)
            end
            let(:subproject) do
              create(:project,
                     parent: project1,
                     types: [type])
            end

            before do
              put :update,
                  params: {
                    ids: work_package_ids,
                    work_package: { version_id: version.id.to_s }
                  }
            end

            subject { response }

            it { is_expected.to be_redirect }

            describe "#work_package" do
              describe "#version" do
                subject { work_packages.map(&:version_id).uniq }

                it { is_expected.to contain_exactly(version.id) }
              end

              describe "#project" do
                subject { work_packages.map(&:project_id).uniq }

                it { is_expected.not_to contain_exactly(subproject.id) }
              end
            end
          end

          describe "set version_id to nil" do
            before do
              # 'none' is a magic value, setting version_id to nil
              # will make the controller ignore that param
              put :update,
                  params: {
                    ids: work_package_ids,
                    work_package: { version_id: "none" }
                  }
            end

            describe "#work_package" do
              describe "#version" do
                subject { work_packages.map(&:version_id).uniq }

                it { is_expected.to eq([nil]) }
              end
            end
          end
        end
      end
    end

    context "w/o notification" do
      let(:send_notification) { "0" }

      describe "#delivery" do
        include_context "update_request"

        let(:delivery_size) { 0 }

        it { expect(response.response_code).to eq(302) }

        it_behaves_like "delivered"
      end
    end

    describe "updating two children with dates to a new parent (Regression #28670)" do
      let(:task1) do
        create(:work_package,
               project: project1,
               start_date: 5.days.ago,
               due_date: Date.current)
      end

      let(:task2) do
        create(:work_package,
               project: project1,
               start_date: 2.days.ago,
               due_date: 1.day.from_now)
      end

      let(:new_parent) do
        create(:work_package, project: project1)
      end

      before do
        put :update,
            params: {
              ids: [task1.id, task2.id],
              notes: "Bulk editing",
              work_package: { parent_id: new_parent.id }
            }
      end

      it "updates the parent dates as well" do
        expect(response.response_code).to eq(302)

        task1.reload
        task2.reload
        new_parent.reload

        expect(task1.parent_id).to eq(new_parent.id)
        expect(task2.parent_id).to eq(new_parent.id)

        expect(new_parent.start_date).to eq(task1.start_date)
        expect(new_parent.due_date).to eq(task2.due_date)
      end
    end
  end

  describe "#destroy" do
    let(:params) { { "ids" => "1", "to_do" => "blubs" } }
    let(:service) { double("destroy wp service") }

    before do
      expect(controller).to receive(:find_work_packages) do
        controller.instance_variable_set(:@work_packages, [stub_work_package])
      end

      expect(controller).to receive(:authorize)
    end

    describe "w/ the cleanup being successful" do
      before do
        expect(stub_work_package).to receive(:reload).and_return(stub_work_package)

        allow(WorkPackages::DeleteService)
          .to receive(:new)
          .with(user:, model: stub_work_package)
          .and_return(service)

        expect(service)
          .to receive(:call)

        expect(WorkPackage)
          .to receive(:cleanup_associated_before_destructing_if_required)
          .with([stub_work_package], user, params["to_do"]).and_return true

        as_logged_in_user(user) do
          delete :destroy, params:
        end
      end

      it "redirects to the project" do
        expect(response).to redirect_to(project_work_packages_path(stub_work_package.project))
      end
    end

    describe "w/o the cleanup being successful" do
      before do
        expect(WorkPackage).to receive(:cleanup_associated_before_destructing_if_required).with([stub_work_package], user,
                                                                                                params["to_do"]).and_return false

        as_logged_in_user(user) do
          delete :destroy, params:
        end
      end

      it "redirects to the project" do
        expect(response).to render_template("destroy")
      end
    end
  end
end
