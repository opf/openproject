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

describe SearchController do
  let!(:project) { FactoryGirl.create(:project,
                                      name: 'eCookbook') }
  let(:user) { FactoryGirl.create(:user,
                                  member_in_project: project) }

  shared_examples_for 'successful search' do
    it { expect(response).to be_success }
    it { expect(response).to render_template('index') }
  end

  before { User.stub(:current).and_return user }

  describe 'project search' do

    before { get :index }

    it_behaves_like 'successful search'

    context 'search parameter' do
      subject { get :index, q: "cook" }

      it_behaves_like 'successful search'
    end
  end

  describe 'work package search' do
    let!(:work_package_1) { FactoryGirl.create(:work_package,
                                               subject: "This is a test issue",
                                               project: project) }
    let!(:work_package_2) { FactoryGirl.create(:work_package,
                                               subject: "Issue test 2",
                                               project: project,
                                               status: FactoryGirl.create(:closed_status)) }

    before { get :index, q: "issue", issues: 1 }

    it_behaves_like 'successful search'

    describe :result do

      it { expect(assigns(:results).count).to be(2) }

      it { expect(assigns(:results)).to include(work_package_1) }

      it { expect(assigns(:results)).to include(work_package_2) }

      describe :view do
        render_views

        it "marks closed work packages" do
          assert_select "dt.work_package-closed" do
            assert_select "a", text: Regexp.new(work_package_2.status.name)
          end
        end
      end
    end
  end
end
