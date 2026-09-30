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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Users::Invitation::FormModel do
  subject(:form_model) { described_class.new }

  let(:project) { build_stubbed(:project) }

  describe "validations" do
    describe "principal_type" do
      context "with enterprise token allowing placeholder users" do
        before do
          allow(EnterpriseToken)
            .to receive(:allows_to?)
            .with(:placeholder_users)
            .and_return(true)
        end

        context "when validating on project_step" do
          it "accepts User as principal_type" do
            form_model.project = project
            form_model.principal_type = "User"

            expect(form_model).to be_valid(:project_step)
          end

          it "accepts PlaceholderUser as principal_type" do
            form_model.project = project
            form_model.principal_type = "PlaceholderUser"

            expect(form_model).to be_valid(:project_step)
          end

          it "accepts Group as principal_type" do
            form_model.project = project
            form_model.principal_type = "Group"

            expect(form_model).to be_valid(:project_step)
          end

          it "rejects invalid principal_type" do
            form_model.project = project
            form_model.principal_type = "InvalidType"

            expect(form_model).not_to be_valid(:project_step)
            expect(form_model.errors[:principal_type]).to be_present
          end

          it "rejects nil principal_type" do
            form_model.project = project
            form_model.principal_type = nil

            expect(form_model).not_to be_valid(:project_step)
            expect(form_model.errors[:principal_type]).to be_present
          end
        end
      end

      context "without enterprise token allowing placeholder users" do
        before do
          allow(EnterpriseToken)
            .to receive(:allows_to?)
            .with(:placeholder_users)
            .and_return(false)
        end

        context "when validating on project_step" do
          it "accepts User as principal_type" do
            form_model.project = project
            form_model.principal_type = "User"

            expect(form_model).to be_valid(:project_step)
          end

          it "accepts Group as principal_type" do
            form_model.project = project
            form_model.principal_type = "Group"

            expect(form_model).to be_valid(:project_step)
          end

          it "rejects PlaceholderUser as principal_type" do
            form_model.project = project
            form_model.principal_type = "PlaceholderUser"

            expect(form_model).not_to be_valid(:project_step)
            expect(form_model.errors[:principal_type]).to be_present
          end

          it "rejects invalid principal_type" do
            form_model.project = project
            form_model.principal_type = "InvalidType"

            expect(form_model).not_to be_valid(:project_step)
            expect(form_model.errors[:principal_type]).to be_present
          end

          it "rejects nil principal_type" do
            form_model.project = project
            form_model.principal_type = nil

            expect(form_model).not_to be_valid(:project_step)
            expect(form_model.errors[:principal_type]).to be_present
          end
        end
      end
    end

    describe "project_id" do
      context "when validating on project_step" do
        it "requires project_id to be present" do
          form_model.principal_type = "User"

          expect(form_model).not_to be_valid(:project_step)
          expect(form_model.errors[:project_id]).to be_present
        end

        it "is valid when project_id is present" do
          form_model.project = project
          form_model.principal_type = "User"

          expect(form_model).to be_valid(:project_step)
        end
      end
    end

    describe "id_or_email" do
      context "when validating on principal_step" do
        it "requires id_or_email to be present" do
          form_model.role_id = 1

          expect(form_model).not_to be_valid(:principal_step)
          expect(form_model.errors[:id_or_email]).to be_present
        end

        it "is valid when id_or_email is present" do
          form_model.id_or_email = "user@example.com"
          form_model.role_id = 1

          expect(form_model).to be_valid(:principal_step)
        end
      end
    end

    describe "role_id" do
      context "when validating on principal_step" do
        it "requires role_id to be present" do
          form_model.id_or_email = "user@example.com"

          expect(form_model).not_to be_valid(:principal_step)
          expect(form_model.errors[:role_id]).to be_present
        end

        it "is valid when role_id is present" do
          form_model.id_or_email = "user@example.com"
          form_model.role_id = 1

          expect(form_model).to be_valid(:principal_step)
        end
      end
    end
  end

  describe ".available_principal_types" do
    context "with enterprise token allowing placeholder users" do
      before do
        allow(EnterpriseToken)
          .to receive(:allows_to?)
          .with(:placeholder_users)
          .and_return(true)
      end

      it "returns User, PlaceholderUser, and Group" do
        expect(described_class.available_principal_types).to eq(%w[User PlaceholderUser Group])
      end
    end

    context "without enterprise token allowing placeholder users" do
      before do
        allow(EnterpriseToken)
          .to receive(:allows_to?)
          .with(:placeholder_users)
          .and_return(false)
      end

      it "returns User and Group" do
        expect(described_class.available_principal_types).to eq(%w[User Group])
      end
    end
  end

  describe "#project_name" do
    it "returns the project name when project is present" do
      form_model.project = project
      expect(form_model.project_name).to eq(project.name)
    end

    it "returns the project_id when project is not present" do
      form_model.project_id = 123
      expect(form_model.project_name).to eq(123)
    end
  end

  describe "#to_h" do
    it "returns a hash with all attributes" do
      form_model.project_id = 1
      form_model.role_id = 2
      form_model.principal_type = "User"
      form_model.id_or_email = "user@example.com"
      form_model.message = "Welcome!"

      expect(form_model.to_h).to eq({
                                      project_id: 1,
                                      role_id: 2,
                                      principal_type: "User",
                                      id_or_email: "user@example.com",
                                      message: "Welcome!"
                                    })
    end
  end
end
