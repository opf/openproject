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

describe WorkPackages::BulkController do
  let(:user) { FactoryGirl.create(:user) }
  let(:custom_field_value) { '125' }
  let(:custom_field_1) { FactoryGirl.create(:work_package_custom_field,
                                            field_format: 'string',
                                            is_for_all: true) }
  let(:custom_field_2) { FactoryGirl.create(:work_package_custom_field) }
  let(:status) { FactoryGirl.create(:status) }
  let(:type) { FactoryGirl.create(:type_standard,
                                  custom_fields: [custom_field_1, custom_field_2]) }
  let(:project_1) { FactoryGirl.create(:project,
                                       types: [type],
                                       work_package_custom_fields: [custom_field_2]) }
  let(:project_2) { FactoryGirl.create(:project,
                                       types: [type]) }
  let(:role) { FactoryGirl.create(:role,
                                  permissions: [:edit_work_packages,
                                                :view_work_packages,
                                                :manage_subtasks]) }
  let(:member_1) { FactoryGirl.create(:member,
                                      project: project_1,
                                      principal: user,
                                      roles: [role]) }
  let(:member_2) { FactoryGirl.create(:member,
                                      project: project_2,
                                      principal: user,
                                      roles: [role]) }
  let(:work_package_1) { FactoryGirl.create(:work_package,
                                            author: user,
                                            assigned_to: user,
                                            type: type,
                                            status: status,
                                            custom_field_values: { custom_field_1.id => custom_field_value },
                                            project: project_1) }
  let(:work_package_2) { FactoryGirl.create(:work_package,
                                            author: user,
                                            assigned_to: user,
                                            type: type,
                                            status: status,
                                            custom_field_values: { custom_field_1.id => custom_field_value },
                                            project: project_1) }
  let(:work_package_3) { FactoryGirl.create(:work_package,
                                            author: user,
                                            type: type,
                                            status: status,
                                            custom_field_values: { custom_field_1.id => custom_field_value },
                                            project: project_2) }

  let(:stub_work_package) { FactoryGirl.build_stubbed(:work_package) }

  before do
    custom_field_1
    member_1

    User.stub(:current).and_return user
  end

  describe :edit do
    shared_examples_for :response do
      subject { response }

      it { should be_success }

      it { should render_template('edit') }
    end

    context "same project" do
      before { get :edit, ids: [work_package_1.id, work_package_2.id] }

      it_behaves_like :response

      describe :view do
        render_views

        subject { response }

        describe :parent do
          it { assert_tag :input, attributes: { name: 'work_package[parent_id]' } }
        end

        context :custom_field do
          describe :type do
            it { assert_tag :input, attributes: { name: "work_package[custom_field_values][#{custom_field_1.id}]" } }
          end

          describe :project do
            it { assert_tag :select, attributes: { name: "work_package[custom_field_values][#{custom_field_2.id}]" } }
          end
        end
      end
    end

    context "different projects" do
      before do
        member_2

        get :edit, ids: [work_package_1.id, work_package_2.id, work_package_3.id]
      end

      it_behaves_like :response

      describe :view do
        render_views

        subject { response }

        describe :parent do
          it { assert_no_tag :input, attributes: { name: 'work_package[parent_id]' } }
        end

        context :custom_field do
          describe :type do
            it { assert_tag :input, attributes: { name: "work_package[custom_field_values][#{custom_field_1.id}]" } }
          end

          describe :project do
            it { assert_no_tag :select, attributes: { name: "work_package[custom_field_values][#{custom_field_2.id}]" } }
          end
        end
      end
    end
  end

  describe :update do
    let(:work_package_ids) { [work_package_1.id, work_package_2.id] }
    let(:work_packages) { WorkPackage.find_all_by_id(work_package_ids) }
    let(:priority) { FactoryGirl.create(:priority_immediate) }
    let(:group_id) { '' }

    describe :redirect do
      context "in host" do
        let(:url) { '/work_packages' }

        before { put :update, ids: work_package_ids, back_url: url }

        subject { response }

        it { should be_redirect }

        it { should redirect_to(url) }
      end

      context "of host" do
        let(:url) { 'http://google.com' }

        before { put :update, ids: work_package_ids, back_url: url }

        subject { response }

        it { should be_redirect }

        it { should redirect_to(project_work_packages_path(project_1)) }
      end
    end

    shared_context :update_request do
      before do
        put :update,
            ids: work_package_ids,
            notes: 'Bulk editing',
            work_package: { priority_id: priority.id,
                            assigned_to_id: group_id,
                            custom_field_values: { custom_field_1.id.to_s => '' },
                            send_notification: send_notification }
      end
    end

    shared_examples_for :delivered do
      subject { ActionMailer::Base.deliveries.size }

      it { delivery_size }
    end

    context "with notification" do
      let(:send_notification) { '1' }
      let(:delivery_size) { 2 }

      shared_examples_for "updated work package" do
        describe :priority do
          subject { WorkPackage.find_all_by_priority_id(priority.id).collect(&:id) }

          it { should =~ work_package_ids }
        end

        describe :custom_fields do
          let(:result) { [custom_field_value] }

          subject { WorkPackage.find_all_by_id(work_package_ids)
                               .collect {|w| w.custom_value_for(custom_field_1.id).value }
                               .uniq }

          it { should =~ result }
        end

        describe :journal do
          describe :notes do
            let(:result) { ['Bulk editing'] }

            subject { WorkPackage.find_all_by_id(work_package_ids)
                                 .collect {|w| w.last_journal.notes }
                                 .uniq }

            it { should =~ result }
          end

          describe :details do
            let(:result) { [1] }

            subject { WorkPackage.find_all_by_id(work_package_ids)
                                 .collect {|w| w.last_journal.details.size }
                                 .uniq }

            it { should =~ result }
          end
        end
      end

      context "single project" do
        include_context :update_request

        it { response.response_code.should == 302 }

        it_behaves_like :delivered

        it_behaves_like "updated work package"
      end

      context "different projects" do
        let(:work_package_ids) { [work_package_1.id, work_package_2.id, work_package_3.id] }

        context "with permission" do
          before { member_2 }

          include_context :update_request

          it { response.response_code.should == 302 }

          it_behaves_like :delivered

          it_behaves_like "updated work package"
        end

        context "w/o permission" do
          include_context :update_request

          it { response.response_code.should == 403 }

          describe :journal do
            subject { Journal.count }

            it { should eq(work_package_ids.count) }
          end
        end
      end

      describe :properties do
        describe :groups do
          let(:group) { FactoryGirl.create(:group) }
          let(:group_id) { group.id }

          include_context :update_request

          subject { work_packages.collect {|w| w.assigned_to_id }.uniq }

          it { should =~ [group_id] }
        end

        describe :status do
          let(:closed_status) { FactoryGirl.create(:closed_status) }
          let(:workflow) { FactoryGirl.create(:workflow,
                                              role: role,
                                              type_id: type.id,
                                              old_status: status,
                                              new_status: closed_status) }

          before do
            workflow

            put :update,
                ids: work_package_ids,
                work_package: { status_id: closed_status.id }
          end

          subject { work_packages.collect(&:status_id).uniq }

          it { should =~ [closed_status.id] }
        end

        describe :parent do
          let(:parent) { FactoryGirl.create(:work_package,
                                            author: user,
                                            project: project_1) }

          before do
            put :update,
                ids: work_package_ids,
                work_package: { parent_id: parent.id }
          end

          subject { work_packages.collect(&:parent_id).uniq }

          it { should =~ [parent.id] }
        end

        describe :custom_fields do
          let(:result) { '777' }

          before do
            put :update,
                ids: work_package_ids,
                work_package: { custom_field_values: { custom_field_1.id.to_s => result } }
          end

          subject { work_packages.collect {|w| w.custom_value_for(custom_field_1.id).value }
                                 .uniq }

          it { should =~ [result] }
        end

        describe :unassign do
          before do
            put :update,
                ids: work_package_ids,
                work_package: { assigned_to_id: 'none' }
          end

          subject { work_packages.collect(&:assigned_to_id).uniq }

          it { should =~ [nil] }
        end

        describe :version do
          let(:version) { FactoryGirl.create(:version,
                                             status: 'open',
                                             sharing: 'tree',
                                             project: subproject) }
          let(:subproject) { FactoryGirl.create(:project,
                                                parent: project_1,
                                                types: [type]) }

          before do
            put :update,
                ids: work_package_ids,
                work_package: { fixed_version_id: version.id.to_s }
          end

          subject { response }

          it { should be_redirect }

          describe :work_package do
            describe :fixed_version do
              subject { work_packages.collect(&:fixed_version_id).uniq }

              it { should =~ [version.id] }
            end

            describe :project do
              subject { work_packages.collect(&:project_id).uniq }

              it { should_not =~ [subproject.id] }
            end
          end
        end
      end
    end

    context "w/o notification" do
      let(:send_notification) { '0' }

      describe :delivery do
        include_context :update_request

        it { response.response_code.should == 302 }

        let(:delivery_size) { 0 }

        it_behaves_like :delivered
      end
    end
  end

  describe :destroy do
    let(:params) { { "ids" => "1", "to_do" => "blubs" } }

    before do
      controller.should_receive(:find_work_packages) do
        controller.instance_variable_set(:@work_packages, [stub_work_package])
      end

      controller.should_receive(:authorize)
    end

    describe 'w/ the cleanup beeing successful' do
      before do
        stub_work_package.should_receive(:reload).and_return(stub_work_package)
        stub_work_package.should_receive(:destroy)

        WorkPackage.should_receive(:cleanup_associated_before_destructing_if_required).with([stub_work_package], user, params["to_do"]).and_return true

        as_logged_in_user(user) do
          delete :destroy, params
        end
      end

      it 'should redirect to the project' do
        response.should redirect_to(project_work_packages_path(stub_work_package.project))
      end
    end

    describe 'w/o the cleanup beeing successful' do
      before do
        WorkPackage.should_receive(:cleanup_associated_before_destructing_if_required).with([stub_work_package], user, params["to_do"]).and_return false

        as_logged_in_user(user) do
          delete :destroy, params
        end
      end

      it 'should redirect to the project' do
        response.should render_template('destroy')
      end
    end
  end
end
