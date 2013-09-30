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

describe CategoriesController do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role,
                                  permissions: [:manage_categories]) }
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

  describe :new do
    before { get :new, project_id: project.id }

    subject { response }

    it { should be_success }

    it { should render_template('new') }
  end

  describe :create do
    let(:category_name) { 'New category' }

    before { post :create,
                  project_id: project.id,
                  category: { name: category_name,
                              assigned_to_id: user.id } }

    describe :response do
      subject { response }

      it { should be_redirect }

      it { should redirect_to("/projects/#{project.identifier}/settings/categories") }
    end

    describe :categories do
      subject { IssueCategory.find_by_name(category_name) }

      it { subject.project_id.should eq(project.id) }

      it { subject.assigned_to_id.should eq(user.id) }
    end
  end
end
