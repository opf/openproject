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

RSpec.describe Label do
  describe "validations" do
    it "is valid with a name" do
      expect(build(:label, name: "urgent")).to be_valid
    end

    it "requires a name" do
      expect(build(:label, name: "")).not_to be_valid
    end

    it "caps the name at 255 characters" do
      expect(build(:label, name: "a" * 256)).not_to be_valid
    end

    it "rejects a name that only differs in case from an existing label" do
      create(:label, name: "hello")

      expect(build(:label, name: "Hello")).not_to be_valid
    end

    it "is backed by a case-insensitive unique index" do
      create(:label, name: "hello")

      expect { described_class.insert_all!([{ name: "HELLO", created_at: Time.current, updated_at: Time.current }]) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#destroy" do
    it "removes its labelings" do
      label = create(:label)
      labeling = create(:labeling, label:)

      label.destroy!

      expect(Labeling.where(id: labeling.id)).not_to exist
    end
  end

  describe "#work_packages" do
    it "returns the labeled work packages" do
      label = create(:label)
      labeled = create_list(:work_package, 2)
      labeled.each { create(:labeling, label:, labelable: it) }
      create(:work_package)

      expect(label.work_packages).to match_array(labeled)
    end
  end
end
