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

describe IssuesController do
  let(:user) { FactoryGirl.create(:user) }
  let(:custom_field_1) { FactoryGirl.create(:work_package_custom_field,
                                            field_format: 'date',
                                            is_for_all: true) }
  let(:custom_field_2) { FactoryGirl.create(:work_package_custom_field) }
  let(:type) { FactoryGirl.create(:type_standard) }
  let(:project_1) { FactoryGirl.create(:project,
                                       types: [type],
                                       work_package_custom_fields: [custom_field_2]) }
  let(:project_2) { FactoryGirl.create(:project,
                                       types: [type]) }
  let(:role) { FactoryGirl.create(:role,
                                  permissions: [:edit_work_packages,
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
                                            type: type,
                                            project: project_1) }
  let(:work_package_2) { FactoryGirl.create(:work_package,
                                            author: user,
                                            type: type,
                                            project: project_1) }
  let(:work_package_3) { FactoryGirl.create(:work_package,
                                            author: user,
                                            type: type,
                                            project: project_2) }

  before do
    custom_field_1
    member_1

    User.stub(:current).and_return user
  end

  describe :bulk_edit do
    shared_examples_for :response do
      subject { response }

      it { should be_success }

      it { should render_template('bulk_edit') }
    end

    context "same project" do
      before { get :bulk_edit, ids: [work_package_1.id, work_package_2.id] }

      it_behaves_like :response

      describe :view do
        render_views

        subject { response }

        describe :parent do
          it { assert_tag :input, attributes: { name: 'issue[parent_id]' } }
        end

        context :custom_field do
          describe :type do
            it { assert_tag :input, attributes: { name: "issue[custom_field_values][#{custom_field_1.id}]" } }
          end

          describe :project do
            it { assert_tag :select, attributes: { name: "issue[custom_field_values][#{custom_field_2.id}]" } }
          end
        end
      end
    end

    context "different projects" do
      before do
        member_2

        get :bulk_edit, ids: [work_package_1.id, work_package_2.id, work_package_3.id]
      end

      it_behaves_like :response

      describe :view do
        render_views

        subject { response }

        describe :parent do
          it { assert_no_tag :input, attributes: { name: 'issue[parent_id]' } }
        end

        context :custom_field do
          describe :type do
            it { assert_tag :input, attributes: { name: "issue[custom_field_values][#{custom_field_1.id}]" } }
          end

          describe :project do
            it { assert_no_tag :select, attributes: { name: "issue[custom_field_values][#{custom_field_2.id}]" } }
          end
        end
      end
    end
  end

  describe :bulk_edit do
  end
end
