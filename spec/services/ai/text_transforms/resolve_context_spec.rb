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

  shared_examples "fails with" do |error, **details|
    it "fails with #{error}" do
      expect(call).to be_failure
      expect(call.errors.details[:base]).to eq([{ error:, **details }])
    end
  end

  context "without ids" do
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

      it_behaves_like "fails with", :not_found, model: :work_package
    end

    context "when the user may not edit the work package" do
      let(:current_user) { viewer }

      it_behaves_like "fails with", :forbidden
    end

    context "when the work package does not exist" do
      let(:params) { { work_package_id: 0 } }

      it_behaves_like "fails with", :not_found, model: :work_package
    end

    context "when only the logged in user has access" do
      let(:current_user) { stranger }

      before { allow(User).to receive(:current).and_return(user) }

      it_behaves_like "fails with", :not_found, model: :work_package
    end
  end

  context "with a project and type id" do
    let(:params) { { project_id: project.id, type_id: type.id } }

    it "resolves the new work package context" do
      expect(call).to be_success
      expect(call.result).to have_attributes(work_package: nil, project:, type:)
    end

    context "when the project is invisible to the user" do
      let(:current_user) { stranger }

      it_behaves_like "fails with", :not_found, model: :project
    end

    context "when the user may not add work packages" do
      let(:current_user) { viewer }

      it_behaves_like "fails with", :forbidden
    end

    context "when the type is not enabled in the project" do
      let(:params) { { project_id: project.id, type_id: create(:type).id } }

      it_behaves_like "fails with", :not_found, model: :type
    end

    context "without a type id" do
      let(:params) { { project_id: project.id } }

      it_behaves_like "fails with", :not_found, model: :type
    end
  end
end
