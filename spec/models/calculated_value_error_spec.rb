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

RSpec.describe CalculatedValueError do
  shared_let(:project) { create(:project) }
  shared_let(:custom_field) { create(:custom_field) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:customized) }
    it { is_expected.to validate_presence_of(:custom_field) }

    it "validates uniqueness of customized scoped to custom_field_id and error_code" do
      # Create an initial record
      create(
        :calculated_value_error,
        customized: project,
        custom_field: custom_field,
        error_code: "ERROR_MATHEMATICAL"
      )

      # Try to create a duplicate record
      duplicate = build(
        :calculated_value_error,
        customized: project,
        custom_field: custom_field,
        error_code: "ERROR_MATHEMATICAL"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:customized_type]).to include("has already been taken.")
    end

    it "validates the error_code is one of the allowed values" do
      expect(subject).to validate_inclusion_of(:error_code).in_array(described_class::VALID_ERROR_CODES)
    end
  end
end
