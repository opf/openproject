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
    let(:model) { create(:type, :with_subject_pattern).default_variant }
    let(:params) { Hash.new }

    subject(:service) { described_class.new(user:, model:, contract_class: UpdateDefaultsContract) }

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
  end
end
