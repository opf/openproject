#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
require_relative "shared_contract_examples"

RSpec.describe Projects::CreateContract do
  it_behaves_like "project contract" do
    let(:project) do
      Project.new(name: project_name,
                  identifier: project_identifier,
                  description: project_description,
                  active: project_active,
                  public: project_public,
                  parent: project_parent,
                  status_code: project_status_code,
                  status_explanation: project_status_explanation)
    end
    let(:global_permissions) { [:add_project] }
    let(:validated_contract) do
      contract.tap(&:validate)
    end

    subject(:contract) { described_class.new(project, current_user) }

    context "if the identifier is nil" do
      let(:project_identifier) { nil }

      it "is replaced for new project" do
        expect_valid(true)
      end
    end

    describe "writing read-only attributes" do
      shared_examples "can not write" do |attribute, value|
        it "can not write #{attribute}", :aggregate_failures do
          expect(contract.writable_attributes).not_to include(attribute.to_s)

          project.send(:"#{attribute}=", value)
          expect(validated_contract).not_to be_valid
          expect(validated_contract.errors[attribute]).to include "was attempted to be written but is not writable."
        end
      end

      context "when enabled for admin", with_settings: { apiv3_write_readonly_attributes: true } do
        let(:current_user) { build_stubbed(:admin) }

        it_behaves_like "can not write", :updated_at, 1.day.ago

        it "can write created_at", :aggregate_failures do
          expect(contract.writable_attributes).to include("created_at")

          project.created_at = 10.days.ago
          expect(validated_contract.errors[:created_at]).to be_empty
        end
      end

      context "when disabled for admin", with_settings: { apiv3_write_readonly_attributes: false } do
        let(:current_user) { build_stubbed(:admin) }

        it_behaves_like "can not write", :created_at, 1.day.ago
        it_behaves_like "can not write", :updated_at, 1.day.ago
      end

      context "when enabled for regular user", with_settings: { apiv3_write_readonly_attributes: true } do
        it_behaves_like "can not write", :created_at, 1.day.ago
        it_behaves_like "can not write", :updated_at, 1.day.ago
      end

      context "when disabled for regular user", with_settings: { apiv3_write_readonly_attributes: false } do
        it_behaves_like "can not write", :created_at, 1.day.ago
        it_behaves_like "can not write", :updated_at, 1.day.ago
      end
    end
  end
end
