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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

module WorkPackageTypes
  RSpec.describe SetAttributesService, with_ee: [:work_package_subject_generation] do
    let(:user) { create(:admin) }
    let(:model) { create(:type, :with_subject_pattern) }
    let(:params) { Hash.new }

    subject(:service) { described_class.new(user:, model:, contract_class: UpdateSubjectPatternContract) }

    context "when the pattern is malformed rubbish" do
      let(:params) { { patterns: "vader_s_rubber_duck" } }

      it "fails" do
        result = service.call(params)

        expect(result).to be_failure
      end

      it "adds an error on the patterns atrribute" do
        result = service.call(params)
        expect(result.errors.details).to eq(patterns: [{ error: :is_invalid }])
      end

      it "does not override the already existing value on the model" do
        service.call(params)
        expect(model).not_to be_changed
      end
    end

    context "when the pattern is invalid" do
      let(:params) { { patterns: { subject: { blueprint: "{{author}}" } } } }

      it "fails" do
        result = service.call(params)
        expect(result).to be_failure
      end

      it "adds an error on the patterns attribute" do
        result = service.call(params)
        expect(result.errors.details).to eq(patterns: [{ error: "Enabled is missing." }])
      end

      it "does not override the already existing value on the model" do
        service.call(params)
        expect(model).not_to be_changed
      end
    end

    context "when the pattern is blank" do
      let(:params) { { patterns: nil } }

      it "succeeds" do
        expect(service.call(params)).to be_success
      end

      it "sets the patterns to an empty collection" do
        service.call(params)
        expect(model.patterns).to eq(WorkPackageTypes::Patterns::Collection.empty)
      end
    end

    context "if copy workflow source type does not exist" do
      let(:params) { { copy_workflow_from: "1337" } }

      it "fails" do
        result = service.call(params)
        expect(result).to be_failure
      end

      it "adds an error on the copy_workflow_from attribute" do
        result = service.call(params)
        expect(result.errors.details).to eq(copy_workflow_from: [{ error: "Type for workflow copy not found." }])
      end

      it "does not override the already existing value on the model" do
        service.call(params)
        expect(model).not_to be_changed
      end
    end

    context "if copy workflow source type does not have a workflow" do
      let(:wp_type) { create(:type_bug) }
      let(:params) { { copy_workflow_from: wp_type.id.to_s } }

      it "fails" do
        result = service.call(params)
        expect(result).to be_failure
      end

      it "adds an error on the copy_workflow_from attribute" do
        result = service.call(params)
        expect(result.errors.details).to eq(copy_workflow_from: [{ error: "Type for workflow copy has no own workflow." }])
      end

      it "does not override the already existing value on the model" do
        service.call(params)
        expect(model).not_to be_changed
      end
    end

    context "if project ids contain a not existent id" do
      let(:project) { create(:project) }
      let(:params) { { project_ids: [project.id.to_s, "1337"] } }

      it "fails" do
        result = service.call(params)
        expect(result).to be_failure
      end

      it "adds an error on the project_ids attribute" do
        result = service.call(params)
        expect(result.errors.details).to eq(project_ids: [{ error: "Projects with ids 1337 do not exist." }])
      end

      it "does not override the already existing value on the model" do
        service.call(params)
        expect(model).not_to be_changed
      end
    end
  end
end
