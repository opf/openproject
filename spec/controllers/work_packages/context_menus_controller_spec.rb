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

describe WorkPackages::ContextMenusController do
  let(:user) { FactoryGirl.create(:user) }
  let(:type) { FactoryGirl.create(:type_standard) }
  let(:project_1) { FactoryGirl.create(:project,
                                       types: [type]) }
  let(:project_2) { FactoryGirl.create(:project,
                                       types: [type],
                                       is_public: false) }
  let(:role) { FactoryGirl.create(:role,
                                    permissions: [:view_work_packages,
                                                  :add_work_packages,
                                                  :edit_work_packages,
                                                  :move_work_packages,
                                                  :delete_work_packages]) }
  let(:member) { FactoryGirl.create(:member,
                                      project: project_1,
                                      principal: user,
                                      roles: [role]) }
  let(:status_1) { FactoryGirl.create(:status) }
  let(:work_package_1) { FactoryGirl.create(:work_package,
                                            author: user,
                                            type: type,
                                            status: status_1,
                                            project: project_1) }
  let(:work_package_2) { FactoryGirl.create(:work_package,
                                            author: user,
                                            type: type,
                                            status: status_1,
                                            project: project_1) }
  let(:work_package_3) { FactoryGirl.create(:work_package,
                                            author: user,
                                            type: type,
                                            status: status_1,
                                            project: project_2) }

  before do
    member

    User.stub(:current).and_return user
  end

  describe :index do
    render_views

    shared_examples_for "successful response" do
      before { get :index, ids: ids }

      subject { response }

      it { should be_success }

      it { should render_template('context_menu') }
    end

    shared_examples_for :edit do
      let(:edit_link) { "/work_packages/#{ids.first}/edit" }

      it_behaves_like :edit_impl
    end

    shared_examples_for :bulk_edit do
      let(:edit_link) { "/work_packages/bulk/edit?#{ids_link}" }

      it_behaves_like :edit_impl
    end

    shared_examples_for :edit_impl do
      before { get :index, ids: ids }

      it do
        assert_tag tag: 'a',
                   content: 'Edit',
                   attributes: { href: edit_link,
                                 :class => 'icon-edit' }
      end
    end

    shared_examples_for :status do
      let(:status_2) { FactoryGirl.create(:status) }
      let(:status_3) { FactoryGirl.create(:status) }
      let(:workflow_1) { FactoryGirl.create(:workflow,
                                            role: role,
                                            type_id: type.id,
                                            old_status: status_1,
                                            new_status: status_2) }
      let(:workflow_2) { FactoryGirl.create(:workflow,
                                            role: role,
                                            type_id: type.id,
                                            old_status: status_2,
                                            new_status: status_3) }

      before do
        workflow_1
        workflow_2

        get :index, ids: ids
      end

      let(:status_link) { "/work_packages/bulk?#{ids_link}"\
                          "&amp;work_package%5Bstatus_id%5D=#{status_2.id}" }

      it do
        assert_tag tag: 'a',
                   content: status_2.name,
                   attributes: { href: status_link,
                                 :class => '' }
      end
    end

    shared_examples_for :priority do
      let(:priority_immediate) { FactoryGirl.create(:priority_immediate) }
      let(:priority_link) { "/work_packages/bulk?#{ids_link}"\
                            "&amp;work_package%5Bpriority_id%5D=#{priority_immediate.id}" }

      before do
        priority_immediate

        get :index, ids: ids
      end

      it do
        assert_tag :tag => 'a',
                   content: 'Immediate',
                   attributes: { href: priority_link,
                                 :class => '' }
      end
    end

    shared_examples_for :version do
      let(:version_1) { FactoryGirl.create(:version,
                                           project: project_1) }
      let(:version_2) { FactoryGirl.create(:version,
                                           project: project_1) }
      let(:version_link_1) { "/work_packages/bulk?#{ids_link}"\
                             "&amp;work_package%5Bfixed_version_id%5D=#{version_1.id}" }
      let(:version_link_2) { "/work_packages/bulk?#{ids_link}"\
                             "&amp;work_package%5Bfixed_version_id%5D=#{version_2.id}" }

      before do
        version_1
        version_2

        get :index, ids: ids
      end

      it do
        assert_tag tag: 'a',
                   content: version_2.name,
                   attributes: { href: version_link_2,
                                 :class => '' }
      end
    end

    shared_examples_for :assigned_to do
      let(:assigned_to_link) { "/work_packages/bulk?#{ids_link}"\
                               "&amp;work_package%5Bassigned_to_id%5D=#{user.id}" }

      before { get :index, ids: ids }

      it do
        assert_tag tag: 'a',
                   content: user.name,
                   attributes: { href: assigned_to_link,
                                 :class => '' }
      end
    end

    shared_examples_for :duplicate do
      let(:duplicate_link) { "/projects/#{project_1.identifier}/work_packages"\
                             "/new?copy_from=#{ids.first}" }

      before { get :index, ids: ids }

      it do
        assert_tag tag: 'a',
                   content: 'Duplicate',
                   attributes: { href: duplicate_link,
                                 :class => 'icon-duplicate' }
      end
    end

    shared_examples_for :copy do
      let(:copy_link) { "/work_packages/move/new?copy_options%5Bcopy%5D=t&amp;"\
                        "#{ids_link}" }

      before { get :index, ids: ids }

      it do
        assert_tag tag: 'a',
                   content: 'Copy',
                   attributes: { href: copy_link }
      end
    end

    shared_examples_for :move do
      let(:move_link) { "/work_packages/move/new?#{ids_link}" }

      before { get :index, ids: ids }

      it do
        assert_tag tag: 'a',
                   content: 'Move',
                   attributes: { href: move_link }
      end
    end

    shared_examples_for :delete do
      let(:delete_link) { "/work_packages/bulk?#{ids_link}" }

      before { get :index, ids: ids }

      it do
        assert_tag tag: 'a',
                   content: 'Delete',
                   attributes: { href: delete_link }
      end
    end

    context "one work package" do
      let(:ids) { [work_package_1.id] }
      let(:ids_link) { ids.map {|id| "ids%5B%5D=#{id}"}.join('&amp;') }

      it_behaves_like "successful response"

      it_behaves_like :edit

      it_behaves_like :status

      it_behaves_like :priority

      it_behaves_like :version

      it_behaves_like :assigned_to

      it_behaves_like :duplicate

      it_behaves_like :copy

      it_behaves_like :move

      it_behaves_like :delete

      context "anonymous user" do
        let(:anonymous) { FactoryGirl.create(:anonymous) }

        before { User.stub(:current).and_return anonymous }

        it_behaves_like "successful response"

        describe :delete do
          before { get :index, ids: ids }

          it { assert_select "a.disabled", :text => /Delete/ }
        end
      end
    end

    context "multiple work packages" do
      context "in same project" do
        let(:ids) { [work_package_1.id, work_package_2.id] }
        let(:ids_link) { ids.map {|id| "ids%5B%5D=#{id}"}.join('&amp;') }

        it_behaves_like "successful response"

        it_behaves_like :bulk_edit

        it_behaves_like :status

        it_behaves_like :priority

        it_behaves_like :assigned_to

        it_behaves_like :copy

        it_behaves_like :move

        it_behaves_like :delete
      end

      context "in different projects" do
        let(:ids) { [work_package_1.id, work_package_2.id, work_package_3.id] }

        describe "with project rights" do
          let(:ids_link) { ids.map {|id| "ids%5B%5D=#{id}"}.join('&amp;') }
          let(:member_2) { FactoryGirl.create(:member,
                                              project: project_2,
                                              principal: user,
                                              roles: [role]) }

          before { member_2 }

          it_behaves_like "successful response"

          it_behaves_like :bulk_edit

          it_behaves_like :status

          it_behaves_like :priority

          it_behaves_like :assigned_to

          it_behaves_like :delete
        end

        describe "w/o project rights" do
          it_behaves_like "successful response"

          describe :work_packages do
            before { get :index, ids: ids }

            it { assigns(:work_packages).collect(&:id).should =~ [work_package_1.id, work_package_2.id] }
          end
        end
      end
    end
  end
end
