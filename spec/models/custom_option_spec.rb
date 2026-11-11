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

RSpec.describe CustomOption do
  let(:custom_field) do
    cf = build(:wp_custom_field, field_format: "list")
    cf.custom_options.build(value: "some value")

    cf
  end

  let(:custom_option) { custom_field.custom_options.first }

  before do
    custom_field.save!
  end

  describe "validations" do
    let(:project) { create(:project) }

    it "allows a global option to be the default" do
      expect(build(:custom_option, custom_field:, default_value: true)).to be_valid
    end

    it "does not allow a project option to be the default" do
      option = build(:custom_option, custom_field:, project:, default_value: true)

      expect(option).not_to be_valid
      expect(option.errors.symbols_for(:default_value)).to include(:present)
    end

    it "allows a project option that is not the default" do
      expect(build(:custom_option, custom_field:, project:, default_value: false)).to be_valid
    end

    describe "value uniqueness" do
      let(:other_project) { create(:project) }

      before { create(:custom_option, custom_field:, value: "QA", project:) }

      it "does not allow a global option to share the value of another global option" do
        option = build(:custom_option, custom_field:, value: "some value")

        expect(option).not_to be_valid
        expect(option.errors.symbols_for(:value)).to include(:taken)
      end

      it "does not allow a project option to share the value of an option of the same project" do
        option = build(:custom_option, custom_field:, value: "QA", project:)

        expect(option).not_to be_valid
        expect(option.errors.symbols_for(:value)).to include(:taken)
      end

      it "does not allow a global option to share the value of a project option" do
        option = build(:custom_option, custom_field:, value: "QA")

        expect(option).not_to be_valid
        expect(option.errors.symbols_for(:value)).to include(:taken)
      end

      it "does not allow a project option to share the value of a global option" do
        option = build(:custom_option, custom_field:, value: "some value", project: other_project)

        expect(option).not_to be_valid
        expect(option.errors.symbols_for(:value)).to include(:taken)
      end

      it "allows a project option to share the value of another project's option" do
        expect(build(:custom_option, custom_field:, value: "QA", project: other_project)).to be_valid
      end

      it "does not allow a global option to share the value of another global option in a different case" do
        option = build(:custom_option, custom_field:, value: "SOME VALUE")

        expect(option).not_to be_valid
        expect(option.errors.symbols_for(:value)).to include(:taken)
      end

      it "does not allow a project option to share the value of an option of the same project in a different case" do
        option = build(:custom_option, custom_field:, value: "qa", project:)

        expect(option).not_to be_valid
        expect(option.errors.symbols_for(:value)).to include(:taken)
      end

      it "does not allow a global option to share the value of a project option in a different case" do
        option = build(:custom_option, custom_field:, value: "qa")

        expect(option).not_to be_valid
        expect(option.errors.symbols_for(:value)).to include(:taken)
      end

      it "does not allow a project option to share the value of a global option in a different case" do
        option = build(:custom_option, custom_field:, value: "Some Value", project: other_project)

        expect(option).not_to be_valid
        expect(option.errors.symbols_for(:value)).to include(:taken)
      end

      it "allows a project option to share the value of another project's option in a different case" do
        expect(build(:custom_option, custom_field:, value: "qa", project: other_project)).to be_valid
      end

      it "allows an option to change the case of its own value" do
        custom_option.value = "Some Value"

        expect(custom_option).to be_valid
      end

      it "rejects a global option added through the custom field's nested attributes" do
        custom_field.custom_options_attributes = [{ value: "QA", position: 3 }]

        expect(custom_field.save).to be(false)
        expect(custom_field.custom_options.where(project_id: nil, value: "QA")).not_to exist
      end
    end
  end

  describe "saving" do
    it "updates the custom_field's timestamp" do
      timestamp_before = custom_field.updated_at
      sleep 1
      custom_option.touch
      expect(custom_field.reload.updated_at).not_to eql(timestamp_before)
    end
  end

  describe ".destroy" do
    context "with more than one option for the cf" do
      before do
        create(:custom_option, custom_field:)
      end

      it "removes the option" do
        custom_option.destroy

        expect(CustomOption.where(id: custom_option.id).count)
          .to be 0
      end

      it "updates the custom_field's timestamp" do
        timestamp_before = custom_field.updated_at
        sleep 1
        custom_option.destroy
        expect(custom_field.reload.updated_at).not_to eql(timestamp_before)
      end
    end

    context "with only one option for the cf" do
      before do
        custom_option.destroy
      end

      it "reports an error" do
        expect(custom_option.errors[:base])
          .to contain_exactly(I18n.t(:"activerecord.errors.models.custom_field.at_least_one_custom_option"))
      end

      it "does not remove the custom option" do
        expect(CustomOption.where(id: custom_option.id).count)
          .to be 1
      end
    end
  end
end
