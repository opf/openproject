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

RSpec.describe Redmine::Acts::Customizable, "tracking value changes" do
  let(:admin) { create(:admin) }

  let!(:project) { create(:project) }

  before { User.current = admin }

  context "for a non-multi-value custom field" do
    let!(:custom_field) do
      create(:list_project_custom_field,
             name: "List field",
             multi_value: false,
             possible_values: %w[a b c d e],
             projects: [project])
    end

    it "correctly tracks changes" do
      # setting a new value from the empty state
      project.custom_field_values = { custom_field.id => "a" }
      expect(project.custom_field_changes).to eq({ "custom_field_#{custom_field.id}" => [nil, "a"] })

      # saving clears the changes
      project.save!
      expect(project.custom_field_changes).to be_empty
      expect(project.custom_value_for(custom_field).value).to eq("a")

      # setting the same value does not register as a change
      project.custom_field_values = { custom_field.id => "a" }
      expect(project.custom_field_changes).to be_empty

      # saving clears the changes
      project.save!
      expect(project.custom_field_changes).to be_empty
      expect(project.custom_value_for(custom_field).value).to eq("a")

      # removing the value registers as a change
      project.custom_field_values = { custom_field.id => nil }
      expect(project.custom_field_changes).to eq({ "custom_field_#{custom_field.id}" => ["a", nil] })

      # saving clears the changes
      project.save!
      expect(project.custom_field_changes).to be_empty
      expect(project.custom_value_for(custom_field).value).to be_nil
    end
  end

  describe "for a multi-value custom field" do
    let!(:custom_field) do
      create(:list_project_custom_field,
             name: "Multi-list field",
             multi_value: true,
             possible_values: %w[a b c d e],
             projects: [project])
    end

    it "correctly tracks changes" do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      # setting a new value from the empty state
      project.custom_field_values = { custom_field.id => %w[a b] }
      expect(project.custom_field_changes).to eq({ "custom_field_#{custom_field.id}" => [[], %w[a b]] })

      # saving clears the changes
      project.save!
      expect(project.custom_field_changes).to be_empty
      expect(project.custom_value_for(custom_field).filter_map(&:value)).to match_array(%w[a b])

      # setting the same value does not register as a change
      project.custom_field_values = { custom_field.id => %w[a b] }
      expect(project.custom_field_changes).to be_empty

      # saving clears the changes
      project.save!
      expect(project.custom_field_changes).to be_empty
      expect(project.custom_value_for(custom_field).filter_map(&:value)).to match_array(%w[a b])

      # adding a value registers as a change
      project.custom_field_values = { custom_field.id => %w[a b c] }
      expect(project.custom_field_changes).to eq({ "custom_field_#{custom_field.id}" => [%w[a b], %w[a b c]] })
      expect(project.custom_value_for(custom_field).filter_map(&:value)).to match_array(%w[a b c])

      # saving clears the changes
      project.save!
      expect(project.custom_field_changes).to be_empty
      expect(project.custom_value_for(custom_field).filter_map(&:value)).to match_array(%w[a b c])

      # removing a value registers as a change
      project.custom_field_values = { custom_field.id => %w[a b] }
      expect(project.custom_field_changes).to eq({ "custom_field_#{custom_field.id}" => [%w[a b c], %w[a b]] })

      # saving clears the changes
      project.save!
      expect(project.custom_field_changes).to be_empty
      expect(project.custom_value_for(custom_field).filter_map(&:value)).to match_array(%w[a b])

      # removing and adding a value registers as a change
      project.custom_field_values = { custom_field.id => %w[a e] }
      expect(project.custom_field_changes).to eq({ "custom_field_#{custom_field.id}" => [%w[a b], %w[a e]] })

      # saving clears the changes
      project.save!
      expect(project.custom_field_changes).to be_empty
      expect(project.custom_value_for(custom_field).filter_map(&:value)).to match_array(%w[a e])

      # removing all values registers as a change
      project.custom_field_values = { custom_field.id => nil }
      expect(project.custom_field_changes).to eq({ "custom_field_#{custom_field.id}" => [%w[a e], []] })

      # saving clears the changes
      project.save!
      expect(project.custom_field_changes).to be_empty
      expect(project.custom_value_for(custom_field).filter_map(&:value)).to be_blank
    end
  end
end
