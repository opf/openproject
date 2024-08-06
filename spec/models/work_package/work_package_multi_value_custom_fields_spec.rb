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

RSpec.describe WorkPackage do
  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }

  let(:custom_field) do
    create(
      :list_wp_custom_field,
      name: "Ingredients",
      multi_value: true,
      types: [type],
      projects: [project],
      possible_values: ["ham", "onions", "pineapple", "mushrooms"]
    )
  end

  let(:custom_values) do
    custom_field
      .custom_options
      .where(value: ["ham", "onions", "pineapple"])
      .pluck(:id)
      .map(&:to_s)
  end

  let(:work_package) do
    wp = create(:work_package, project:, type:)
    wp.reload
    wp.custom_field_values = {
      custom_field.id => custom_values
    }
    wp.save
    wp
  end

  let(:values) { work_package.custom_value_for(custom_field) }
  let(:typed_values) { work_package.typed_custom_value_for(custom_field.id) }

  it "returns the properly typed values" do
    expect(values.map(&:value)).to eq(custom_values)
    expect(typed_values).to eq(%w(ham onions pineapple))
  end

  context "when value not present" do
    let(:work_package) { create(:work_package, project:, type:) }

    it "returns nil properly" do
      # I suspect this should rather be
      # expect(values.map(&:value)).to eq([nil])
      expect(values.value).to be_nil
      expect(typed_values).to be_nil
    end
  end

  describe "setting and reading values" do
    shared_examples_for "custom field values updates" do
      before do
        # Reload to reset i.e. the saved_changes filter on custom_values
        work_package.reload
      end

      it "touches the work_package" do
        expect do
          work_package.custom_field_values = { custom_field.id => ids }
          work_package.save
        end
          .to(change(work_package, :lock_version))
      end

      it "sets the values" do
        work_package.custom_field_values = { custom_field.id => ids }
        work_package.save

        expect(work_package.send(custom_field.attribute_getter))
          .to eql values
      end
    end

    context "when removing some custom values" do
      it_behaves_like "custom field values updates" do
        let(:ids) { [custom_values.first.to_s] }
        let(:values) { ["ham"] }
      end
    end

    context "when removing all custom values" do
      it_behaves_like "custom field values updates" do
        let(:ids) { [] }
        let(:values) { [nil] }
      end
    end

    context "when adding values" do
      it_behaves_like "custom field values updates" do
        let(:ids) do
          CustomOption.where(value: ["ham", "onions", "pineapple", "mushrooms"]).pluck(:id).map(&:to_s)
        end
        let(:values) { ["ham", "onions", "pineapple", "mushrooms"] }
      end
    end

    context "when first having no values and then adding some" do
      let(:custom_values) { [] }

      it_behaves_like "custom field values updates" do
        let(:ids) do
          CustomOption.where(value: ["ham", "mushrooms"]).pluck(:id).map(&:to_s)
        end
        let(:values) { ["ham", "mushrooms"] }
      end
    end
  end
end
