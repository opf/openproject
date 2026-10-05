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
# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Screens::SchemeService do
  let(:project) { create(:project) }

  describe ".assign" do
    it "creates the project assignment" do
      scheme = create(:screen_scheme)
      result = described_class.assign(project, scheme)
      expect(result).to be_success
      expect(ProjectScreenScheme.find_by(project_id: project.id).scheme).to eq(scheme)
    end

    it "replaces an existing assignment" do
      first = create(:screen_scheme)
      second = create(:screen_scheme, name: "Second")
      described_class.assign(project, first)
      described_class.assign(project, second)
      expect(ProjectScreenScheme.where(project_id: project.id).count).to eq(1)
    end

    it "removes the assignment when passed nil" do
      described_class.assign(project, create(:screen_scheme))
      described_class.assign(project, nil)
      expect(ProjectScreenScheme.find_by(project_id: project.id)).to be_nil
    end

    it "fails for an inactive scheme" do
      scheme = create(:screen_scheme, active: false)
      expect(described_class.assign(project, scheme)).to be_failure
    end
  end

  describe ".create" do
    it "creates a scheme with its type items" do
      type = create(:type)
      screen = create(:create_screen)
      result = described_class.create(name: "Scheme", items: [{ type_id: type.id, create_screen_id: screen.id }])
      expect(result).to be_success
      expect(result.result.items.first.create_screen_id).to eq(screen.id)
    end

    it "rejects duplicate types" do
      type = create(:type)
      result = described_class.create(name: "Scheme",
                                      items: [{ type_id: type.id, create_screen: create(:create_screen) },
                                              { type_id: type.id, create_screen: create(:create_screen) }])
      expect(result).to be_failure
      expect(result.errors.details[:items]).to include(error: :duplicate_types)
    end
  end

  describe ".clone" do
    it "copies the type items" do
      scheme = create(:screen_scheme)
      create(:screen_scheme_item, scheme:, type: create(:type), create_screen: create(:create_screen))
      copy = described_class.clone(scheme).result
      expect(copy.items.size).to eq(1)
    end
  end

  describe ".deactivate" do
    it "toggles active" do
      scheme = create(:screen_scheme)
      described_class.deactivate(scheme)
      expect(scheme.reload.active).to be(false)
    end
  end
end
