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

RSpec.describe CalculatedValues::ErrorsHelper do
  let(:error) { build(:calculated_value_error) }

  shared_let(:custom_field) { create(:custom_field) }
  shared_let(:other_custom_field) { create(:custom_field) }

  subject { described_class }

  describe ".calculated_value_error_msg" do
    it "returns nil when not given a CalculatedValueError" do
      expect(subject.calculated_value_error_msg(1)).to be_nil
    end

    it "returns a human readable error message for the error code" do
      error.error_code = "ERROR_MATHEMATICAL"
      expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.mathematical"))
    end

    it "returns a default message for unknown error codes" do
      error.error_code = "UNKNOWN_ERROR_CODE"
      expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.unknown"))
    end

    describe "missing values" do
      it "includes the custom field name for a missing value" do
        error.missing_custom_field_ids = [custom_field.id]

        error.error_code = "ERROR_MISSING_VALUE"
        expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.missing_value",
                                                                       custom_field_name: custom_field.name))
      end

      it "when there are multiple missing values, only includes the first custom field name" do
        error.missing_custom_field_ids = [other_custom_field.id, custom_field.id]

        error.error_code = "ERROR_MISSING_VALUE"
        expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.missing_value",
                                                                       custom_field_name: other_custom_field.name))
      end

      it "when there are no missing values, it fallbacks to unknown error" do
        error.missing_custom_field_ids = []

        error.error_code = "ERROR_MISSING_VALUE"
        expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.unknown"))
      end

      it "when missing value can't be found, it fallbacks to unknown error" do
        error.missing_custom_field_ids = [0]

        error.error_code = "ERROR_MISSING_VALUE"
        expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.unknown"))
      end

      it "with unexpected missing value, it fallbacks to unknown error" do
        error.missing_custom_field_ids = [nil]

        error.error_code = "ERROR_MISSING_VALUE"
        expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.unknown"))
      end
    end

    describe "disabled values" do
      it "includes the custom field name for a disabled value" do
        error.missing_custom_field_ids = [custom_field.id]

        error.error_code = "ERROR_DISABLED_VALUE"
        expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.disabled_value",
                                                                       custom_field_name: custom_field.name))
      end

      it "when there are multiple disabled values, only includes the first custom field name" do
        error.missing_custom_field_ids = [other_custom_field.id, custom_field.id]

        error.error_code = "ERROR_DISABLED_VALUE"
        expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.disabled_value",
                                                                       custom_field_name: other_custom_field.name))
      end

      it "when there are no disabled values, it fallbacks to unknown error" do
        error.missing_custom_field_ids = []

        error.error_code = "ERROR_DISABLED_VALUE"
        expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.unknown"))
      end

      it "when disabled value can't be found, it fallbacks to unknown error" do
        error.missing_custom_field_ids = [0]

        error.error_code = "ERROR_DISABLED_VALUE"
        expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.unknown"))
      end

      it "with unexpected disabled value, it fallbacks to unknown error" do
        error.missing_custom_field_ids = [nil]

        error.error_code = "ERROR_DISABLED_VALUE"
        expect(subject.calculated_value_error_msg(error)).to eq(I18n.t("calculated_values.errors.unknown"))
      end
    end
  end
end
