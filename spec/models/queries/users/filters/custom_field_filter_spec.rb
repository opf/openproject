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

RSpec.describe Queries::Users::Filters::CustomFieldFilter do
  let(:bool_user_custom_field) { build_stubbed(:user_custom_field, :boolean) }
  let(:int_user_custom_field) { build_stubbed(:user_custom_field, :integer) }
  let(:float_user_custom_field) { build_stubbed(:user_custom_field, :float) }
  let(:text_user_custom_field) { build_stubbed(:user_custom_field, :text) }
  let(:date_user_custom_field) { build_stubbed(:user_custom_field, :date) }
  let(:string_user_custom_field) { build_stubbed(:user_custom_field, :string) }
  let(:custom_field) { list_user_custom_field }
  let(:all_custom_fields) do
    [list_user_custom_field,
     bool_user_custom_field,
     int_user_custom_field,
     float_user_custom_field,
     text_user_custom_field,
     date_user_custom_field,
     string_user_custom_field]
  end
  let(:cf_accessor) { custom_field.column_name }
  let(:instance) do
    described_class.create!(name: cf_accessor, operator: "=")
  end

  shared_let(:list_user_custom_field) { create(:user_custom_field, :list) }

  before do
    allow(UserCustomField)
      .to receive(:all)
      .and_return(all_custom_fields)
  end

  describe "invalid custom field" do
    let(:cf_accessor) { "cf_99999" }
    let(:all_custom_fields) { [] }

    it "raises exception" do
      expect { instance }.to raise_error(Queries::Filters::InvalidError)
    end
  end

  describe ".key" do
    it "matches the cf_<id> accessor pattern" do
      expect(described_class.key).to eql(/cf_(\d+)/)
    end
  end

  describe "instance attributes" do
    it "are valid for every supported custom field format" do
      all_custom_fields.each do |cf|
        filter = described_class.create!(name: "cf_#{cf.id}", operator: "=")
        expect(filter.name).to eql(cf.column_name.to_sym)
        expect(filter.order).to be(20)
        expect(filter.human_name).to eql(cf.name)
      end
    end
  end

  describe "#type" do
    {
      int_user_custom_field: :integer,
      float_user_custom_field: :float,
      text_user_custom_field: :text,
      list_user_custom_field: :list_optional,
      date_user_custom_field: :date,
      bool_user_custom_field: :list,
      string_user_custom_field: :string
    }.each do |cf, expected_type|
      it "is :#{expected_type} for a #{cf.to_s.sub('_user_custom_field', '')} custom field" do
        cf_accessor = send(cf).column_name
        filter = described_class.create!(name: cf_accessor, operator: "=")
        expect(filter.type).to be(expected_type)
      end
    end
  end

  describe ".all_for" do
    before do
      allow(UserCustomField)
        .to receive(:visible)
        .and_return(all_custom_fields)
    end

    it "returns a filter for every visible user custom field" do
      filters = described_class.all_for

      all_custom_fields.each do |cf|
        expect(filters.detect { |filter| filter.name == cf.column_name.to_sym }).not_to be_nil
      end
    end
  end

  describe "#apply_to" do
    shared_let(:job_title_cf) do
      create(:user_custom_field, :list, possible_values: %w[Developer Designer])
    end
    shared_let(:developer_option) { job_title_cf.custom_options.find_by(value: "Developer") }
    shared_let(:designer_option) { job_title_cf.custom_options.find_by(value: "Designer") }
    shared_let(:developer) { create(:user) }
    shared_let(:designer) { create(:user) }
    shared_let(:unassigned) { create(:user) }

    let(:all_custom_fields) { [job_title_cf] }
    let(:cf_accessor) { job_title_cf.column_name }

    before do
      developer.custom_field_values = { job_title_cf.id => developer_option.id }
      developer.save!(validate: false)
      designer.custom_field_values = { job_title_cf.id => designer_option.id }
      designer.save!(validate: false)
    end

    it "filters users matching the selected custom option" do
      instance.values = [developer_option.id.to_s]

      expect(instance.apply_to(User.user)).to contain_exactly(developer)
    end

    it "excludes users matching the selected option for the negated operator" do
      filter = described_class.create!(name: cf_accessor, operator: "!")
      filter.values = [developer_option.id.to_s]

      relation = filter.apply_to(User.user)
      expect(relation).to include(designer, unassigned)
      expect(relation).not_to include(developer)
    end
  end

  describe "round-trip through Queries::Serialization::Filters" do
    let(:coder) { Queries::Serialization::Filters.new(UserQuery) }

    it "loads a serialized custom field filter back into a CustomFieldFilter instance" do
      serialized = [{
        "attribute" => list_user_custom_field.column_name,
        "operator" => "=",
        "values" => [list_user_custom_field.custom_options.first.id.to_s]
      }]

      filters = coder.load(serialized)

      expect(filters.size).to eq(1)
      expect(filters.first).to be_a(Queries::Filters::Shared::CustomFields::ListOptional)
      expect(filters.first.custom_field).to eq(list_user_custom_field)
      expect(filters.first.values).to eq([list_user_custom_field.custom_options.first.id.to_s])
    end
  end
end
