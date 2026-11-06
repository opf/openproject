# frozen_string_literal: true

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

RSpec.describe AI::TextTransforms::ResolveContext do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:work_package) { create(:work_package, project:, type:) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages add_work_packages] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:stranger) { create(:user) }

  let(:current_user) { user }
  let(:params) { {} }

  subject(:call) { described_class.new(user: current_user).call(**params) }

  shared_examples "fails with" do |error, model_class, message|
    it "fails with #{error} on #{model_class}" do
      expect(call).to be_failure
      expect(call.errors.details[:base]).to eq([{ error: }])
      expect(call.errors.first.base).to be_a(model_class)
      expect(call.errors.full_messages).to eq([message])
    end
  end

  shared_examples "not found" do |model_class|
    it_behaves_like "fails with", :error_not_found, model_class, "not found."
  end

  shared_examples "forbidden" do |model_class|
    it_behaves_like "fails with", :error_unauthorized, model_class, "may not be accessed."
  end

  shared_examples "ignores the logged in user" do |model_class|
    context "when only the logged in user has access" do
      let(:current_user) { stranger }

      it "checks the given user" do
        result = User.execute_as(user) { call }

        expect(result).to be_failure
        expect(result.errors.first).to have_attributes(type: :error_not_found, base: be_a(model_class))
      end
    end
  end

  context "without ids" do
    it "resolves no context" do
      expect(call).to be_success
      expect(call.result).to have_attributes(work_package: nil, project: nil, type: nil)
    end
  end

  context "with a type id only" do
    let(:params) { { type_id: type.id } }

    it "resolves no context" do
      expect(call).to be_success
      expect(call.result).to have_attributes(work_package: nil, project: nil, type: nil)
    end
  end

  context "with a work package id" do
    let(:params) { { work_package_id: work_package.id } }

    it "resolves the work package context" do
      expect(call).to be_success
      expect(call.result).to have_attributes(work_package:, project:, type:)
    end

    context "when the work package is invisible to the user" do
      let(:current_user) { stranger }

      it_behaves_like "not found", WorkPackage
    end

    context "when the work package does not exist" do
      let(:params) { { work_package_id: 0 } }

      it_behaves_like "not found", WorkPackage
    end

    context "when the user may not edit the work package" do
      let(:current_user) { viewer }

      it_behaves_like "forbidden", WorkPackage
    end

    context "with a project and type id as well" do
      let(:params) { { work_package_id: work_package.id, project_id: create(:project).id, type_id: create(:type).id } }

      it "resolves the work package context" do
        expect(call.result).to have_attributes(work_package:, project:, type:)
      end
    end

    it_behaves_like "ignores the logged in user", WorkPackage
  end

  context "with a project and type id" do
    let(:params) { { project_id: project.id, type_id: type.id } }

    it "resolves the new work package context" do
      expect(call).to be_success
      expect(call.result).to have_attributes(work_package: nil, project:, type:)
    end

    context "when the project is invisible to the user" do
      let(:current_user) { stranger }

      it_behaves_like "not found", Project
    end

    context "when the project does not exist" do
      let(:params) { { project_id: 0, type_id: type.id } }

      it_behaves_like "not found", Project
    end

    context "when the user may not add work packages" do
      let(:current_user) { viewer }

      it_behaves_like "forbidden", Project
    end

    context "when the type is not enabled in the project" do
      let(:params) { { project_id: project.id, type_id: create(:type).id } }

      it_behaves_like "not found", Type
    end

    context "without a type id" do
      let(:params) { { project_id: project.id } }

      it_behaves_like "not found", Type
    end

    it_behaves_like "ignores the logged in user", Project
  end
end
