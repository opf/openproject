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

RSpec.describe Redmine::Acts::Customizable, "value assignment" do
  shared_let(:type) { create(:type_task) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:custom_field) do
    create(:string_wp_custom_field).tap do |cf|
      type.default_variant.custom_field_ids |= [cf.id]
    end
  end

  let(:work_package) { build(:work_package, project:, type:) }
  let(:stored_values) { work_package.custom_field_values.select { it.custom_field_id == custom_field.id }.map(&:value) }

  before do
    RequestStore.clear!
    work_package.public_send(custom_field.attribute_setter, value)
  end

  context "with an object responding to id" do
    let(:value) { build_stubbed(:user, id: 42) }

    it "stores its id" do
      expect(stored_values).to eq(["42"])
    end
  end

  context "with a Time" do
    let(:value) { Time.find_zone!("Europe/Berlin").local(2026, 10, 1, 14, 30) }

    it "stores it as a single ISO 8601 value" do
      expect(stored_values).to eq(["2026-10-01T14:30:00+02:00"])
    end
  end

  context "with a Date" do
    let(:value) { Date.new(2026, 10, 1) }

    it "stores it as a single ISO 8601 value" do
      expect(stored_values).to eq(["2026-10-01"])
    end
  end

  context "with any other value" do
    let(:value) { 1.5 }

    it "stores its string representation" do
      expect(stored_values).to eq(["1.5"])
    end
  end
end
