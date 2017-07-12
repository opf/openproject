#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe Api::V2::CustomFieldsController, type: :controller do
  describe '#index' do
    let!(:type) { FactoryGirl.create(:type) }
    let!(:custom_field) do
      FactoryGirl.create(:custom_field)
    end
    let!(:wp_custom_field_1) do
      cf = FactoryGirl.create(:work_package_custom_field)

      type.custom_fields << cf

      cf
    end
    let!(:wp_custom_field_2) do
      cf = FactoryGirl.create(:work_package_custom_field)

      type.custom_fields << cf

      cf
    end
    let!(:wp_custom_field_3) do
      cf = FactoryGirl.create(:work_package_custom_field)

      type.custom_fields << cf

      cf
    end
    let!(:wp_custom_field_for_all) do
      cf = FactoryGirl.create(:work_package_custom_field, is_for_all: true)

      type.custom_fields << cf

      cf
    end
    let!(:wp_custom_field_public) do
      cf = FactoryGirl.create(:work_package_custom_field)

      type.custom_fields << cf

      cf
    end
    let(:wp_custom_fields) { [wp_custom_field_1, wp_custom_field_2] }
    let(:project) do
      project = FactoryGirl.create(:project,
                                   is_public: false,
                                   work_package_custom_fields: wp_custom_fields)

      project.types << type

      project
    end
    let(:project_2) do
      project = FactoryGirl.create(:project,
                                   is_public: false,
                                   work_package_custom_fields: wp_custom_fields)
      project.types << type

      project
    end
    let!(:public_project) do
      project = FactoryGirl.create(:public_project,
                                   work_package_custom_fields: [wp_custom_field_public])

      project.types << type

      project
    end

    before do
      Role.non_member
      Role.anonymous
    end

    shared_examples_for 'valid workflow index request' do
      it { expect(response).to render_template('api/v2/custom_fields/index') }
    end

    shared_examples_for 'a user w/o a project' do
      before do
        get :index, format: :xml
      end

      it_behaves_like 'valid workflow index request'

      subject { assigns(:custom_fields) }

      it { expect(subject).to match_array([custom_field, wp_custom_field_for_all, wp_custom_field_public]) }
    end

    describe 'unauthorized access' do
      before do
        allow(Setting).to receive(:login_required).and_return false
      end

      it_behaves_like 'a user w/o a project'
    end

    describe 'authorized access' do
      context 'w/o project' do
        let(:current_user) { FactoryGirl.create(:user) }

        before do
          allow(User).to receive(:current).and_return current_user
        end

        it_behaves_like 'a user w/o a project'
      end

      context 'with project' do
        let(:current_user) { FactoryGirl.create(:user, member_in_projects: [project, project_2]) }

        before do
          allow(User).to receive(:current).and_return current_user

          get :index, format: :xml
        end

        it_behaves_like 'valid workflow index request'

        subject { assigns(:custom_fields) }

        it do
          is_expected
            .to match_array([custom_field,
                             wp_custom_field_1,
                             wp_custom_field_2,
                             wp_custom_field_for_all,
                             wp_custom_field_public])
        end
      end

      context 'as admin with project' do
        let(:current_user) { FactoryGirl.create(:admin) }

        before do
          allow(User).to receive(:current).and_return current_user

          get :index, format: :xml
        end

        it_behaves_like 'valid workflow index request'

        subject { assigns(:custom_fields) }

        it { expect(subject.count).to eq(6) }
      end
    end
  end
end
