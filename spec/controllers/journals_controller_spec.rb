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

describe JournalsController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project_with_types) }
  let(:role) { FactoryGirl.create(:role, :permissions => [:view_work_package]) }
  let(:member) { FactoryGirl.build(:member, :project => project,
                                            :roles => [role],
                                            :principal => user) }
  let(:work_package) { FactoryGirl.build(:work_package, :type => project.types.first,
                                                        :author => user,
                                                        :project => project,
                                                        :description => '') }
  let(:journal) { FactoryGirl.create(:work_package_journal,
                  journable: work_package,
                  user: user) }

  describe "GET diff" do
    render_views

    before do
      work_package.update_attribute :description, 'description'
      params = { :id => work_package.journals.last.id.to_s, :field => :description, :format => 'js' }

      get :diff, params
    end

    it { expect(response).to be_success }
    it { expect(response.body.strip).to eq("<div class=\"text-diff\">\n  <ins class=\"diffmod\">description</ins>\n</div>") }
  end

  describe :edit do
    describe 'authorization' do
      before do
        member.save and user.reload
        allow(User).to receive(:current).and_return user

        work_package.update_attribute :description, 'description'
        role.add_permission! *permissions

        get :edit, id: journal.id
      end

      context 'with permissions to edit work packages and edit own work package notes' do
        let(:permissions) { [:edit_work_packages, :edit_own_work_package_notes] }

        example { assert_response :success }
      end

      context 'without permission to edit work packages' do
        let(:permissions) { [:edit_own_work_package_notes] }

        example { assert_response :success }
      end

      context 'without permission to edit journals' do
        let(:permissions) { [:edit_work_packages] }

        example { assert_response :forbidden }
      end
    end
  end
end
