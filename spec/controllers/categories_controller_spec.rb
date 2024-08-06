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

RSpec.describe CategoriesController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:role) do
    create(:project_role,
           permissions: [:manage_categories])
  end
  let(:member) do
    create(:member,
           project:,
           principal: user,
           roles: [role])
  end

  before do
    member

    allow(User).to receive(:current).and_return user
  end

  shared_examples_for "redirect" do
    subject { response }

    it { is_expected.to be_redirect }

    it { is_expected.to redirect_to("/projects/#{project.identifier}/settings/categories") }
  end

  describe "#new" do
    before do
      get :new, params: { project_id: project.id }
    end

    subject { response }

    it { is_expected.to be_successful }

    it { is_expected.to render_template("new") }
  end

  describe "#create" do
    let(:category_name) { "New category" }

    before do
      post :create,
           params: {
             project_id: project.id,
             category: { name: category_name,
                         assigned_to_id: user.id }
           }
    end

    describe "#categories" do
      subject { Category.find_by(name: category_name) }

      it { expect(subject.project_id).to eq(project.id) }

      it { expect(subject.assigned_to_id).to eq(user.id) }
    end

    it_behaves_like "redirect"
  end

  describe "#edit" do
    let(:category) do
      create(:category,
             project:)
    end

    subject { response }

    before do
      get :edit, params: { id: category_id }
    end

    context "valid category" do
      let(:category_id) { category.id }

      it { is_expected.to be_successful }
      it { is_expected.to render_template("edit") }
    end

    context "invalid category" do
      let(:category_id) { 404 }

      it { is_expected.to be_not_found }
    end
  end

  describe "#update" do
    let(:name) { "Testing" }

    context "valid category" do
      let(:category) do
        create(:category,
               project:)
      end

      before do
        post :update,
             params: {
               id: category.id,
               category: { name: }
             }
      end

      subject { Category.find(category.id).name }

      it { is_expected.to eq(name) }

      describe "#category_count" do
        subject { Category.count }

        it { is_expected.to eq(1) }
      end

      it_behaves_like "redirect"
    end

    context "invalid category" do
      before do
        post :update,
             params: {
               id: 404,
               category: { name: }
             }
      end

      subject { response.response_code }

      it { is_expected.to eq(404) }
    end
  end

  describe "#destroy" do
    let(:category) do
      create(:category,
             project:)
    end
    let(:work_package) do
      create(:work_package,
             project:,
             category:)
    end

    before { category }

    shared_examples_for "delete" do
      subject { Category.find_by(id: category.id) }

      it { is_expected.to be_nil }
    end

    context "unused" do
      before do
        delete :destroy, params: { id: category.id }
      end

      it_behaves_like "redirect"

      it_behaves_like "delete"
    end

    context "in use" do
      before do
        work_package

        delete :destroy, params: { id: category.id }
      end

      subject { Category.find_by(id: category.id) }

      it { is_expected.not_to be_nil }

      describe "#response" do
        subject { response }

        it { is_expected.to be_successful }

        it { is_expected.to render_template("destroy") }
      end
    end

    describe "#reassign" do
      let(:target) do
        create(:category,
               project:)
      end

      before do
        work_package

        delete :destroy,
               params: {
                 id: category.id,
                 todo: "reassign",
                 reassign_to_id: target.id
               }
      end

      subject { work_package.reload.category_id }

      it { is_expected.to eq(target.id) }

      it_behaves_like "delete"

      it_behaves_like "redirect"
    end

    describe "#nullify" do
      before do
        work_package

        delete :destroy,
               params: {
                 id: category.id,
                 todo: "nullify"
               }
      end

      subject { work_package.reload.category_id }

      it { is_expected.to be_nil }

      it_behaves_like "delete"

      it_behaves_like "redirect"
    end
  end
end
