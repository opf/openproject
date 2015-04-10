#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

describe CategoriesController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project) }
  let(:role) {
    FactoryGirl.create(:role,
                       permissions: [:manage_categories])
  }
  let(:member) {
    FactoryGirl.create(:member,
                       project: project,
                       principal: user,
                       roles: [role])
  }

  before do
    member

    allow(User).to receive(:current).and_return user
  end

  shared_examples_for :redirect do
    subject { response }

    it { is_expected.to be_redirect }

    it { is_expected.to redirect_to("/projects/#{project.identifier}/settings/categories") }
  end

  describe '#new' do
    before { get :new, project_id: project.id }

    subject { response }

    it { is_expected.to be_success }

    it { is_expected.to render_template('new') }
  end

  describe '#create' do
    let(:category_name) { 'New category' }

    before {
      post :create,
           project_id: project.id,
           category: { name: category_name,
                       assigned_to_id: user.id }
    }

    describe '#categories' do
      subject { Category.find_by_name(category_name) }

      it { expect(subject.project_id).to eq(project.id) }

      it { expect(subject.assigned_to_id).to eq(user.id) }
    end

    it_behaves_like :redirect
  end

  describe '#edit' do
    let(:name) { 'Testing' }

    context 'valid category' do
      let(:category) {
        FactoryGirl.create(:category,
                           project: project)
      }

      before {
        post :update,
             id: category.id,
             category: { name: name }
      }

      subject { Category.find(category.id).name }

      it { is_expected.to eq(name) }

      describe '#category_count' do
        subject { Category.count }

        it { is_expected.to eq(1) }
      end

      it_behaves_like :redirect
    end

    context 'invalid category' do
      before {
        post :update,
             id: 404,
             category: { name: name }
      }

      subject { response.response_code }

      it { is_expected.to eq(404) }
    end
  end

  describe '#destroy' do
    let(:category) {
      FactoryGirl.create(:category,
                         project: project)
    }
    let(:work_package) {
      FactoryGirl.create(:work_package,
                         project: project,
                         category: category)
    }

    before { category }

    shared_examples_for :delete do
      subject { Category.find_by_id(category.id) }

      it { is_expected.to be_nil }
    end

    context 'unused' do
      before { delete :destroy, id: category.id }

      it_behaves_like :redirect

      it_behaves_like :delete
    end

    context 'in use' do
      before do
        work_package

        delete :destroy, id: category.id
      end

      subject { Category.find_by_id(category.id) }

      it { is_expected.not_to be_nil }

      describe '#response' do
        subject { response }

        it { is_expected.to be_success }

        it { is_expected.to render_template('destroy') }
      end
    end

    describe '#reassign' do
      let(:target) {
        FactoryGirl.create(:category,
                           project: project)
      }
      before do
        work_package

        delete :destroy,
               id: category.id,
               todo: 'reassign',
               reassign_to_id: target.id
      end

      subject { work_package.reload.category_id }

      it { is_expected.to eq(target.id) }

      it_behaves_like :delete

      it_behaves_like :redirect
    end

    describe '#nullify' do
      before do
        work_package

        delete :destroy,
               id: category.id,
               todo: 'nullify'
      end

      subject { work_package.reload.category_id }

      it { is_expected.to be_nil }

      it_behaves_like :delete

      it_behaves_like :redirect
    end
  end
end
