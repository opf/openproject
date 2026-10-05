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

RSpec.describe "Screen invariants" do # rubocop:disable RSpec/DescribeClass
  def timestamps = { created_at: Time.current, updated_at: Time.current }

  let(:screen) { create(:screen) }
  let(:other_screen) { create(:screen, name: "Other") }
  let(:section) { create(:screen_section, screen:) }

  describe "database constraints" do
    it "rejects an item whose section belongs to another screen" do
      expect do
        ScreenItem.insert_all!([{ screen_id: other_screen.id, section_id: section.id, field_key: "subject",
                                  position: 0, width: "full", visible: true, **timestamps }])
      end.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "rejects an invalid screen_type by raw SQL" do
      expect do
        Screen.insert_all!([{ name: "Bad", screen_type: "foo", active: true, **timestamps }])
      end.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects an invalid width by raw SQL" do
      expect do
        ScreenItem.insert_all!([{ screen_id: screen.id, section_id: section.id, field_key: "subject",
                                  position: 0, width: "third", visible: true, **timestamps }])
      end.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "rejects a duplicate field key by raw SQL" do
      ScreenItem.create!(screen:, section:, field_key: "subject")
      expect do
        ScreenItem.insert_all!([{ screen_id: screen.id, section_id: section.id, field_key: "subject",
                                  position: 1, width: "full", visible: true, **timestamps }])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "refuses to delete a screen used by a scheme even with raw SQL" do
      scheme = create(:screen_scheme)
      create(:screen_scheme_item, scheme:, type: create(:type), create_screen: screen)
      expect { Screen.where(id: screen.id).delete_all }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "cascades" do
    it "cascades screen_scheme_items when a type is deleted but keeps screens" do
      scheme = create(:screen_scheme)
      type = create(:type)
      create(:screen_scheme_item, scheme:, type:, create_screen: screen)

      expect { type.destroy }.to change(ScreenSchemeItem, :count).by(-1)
      expect(Screen.exists?(screen.id)).to be true
    end

    it "cascades project_screen_schemes when a project is deleted" do
      assignment = create(:project_screen_scheme)
      expect { assignment.project.destroy }.to change(ProjectScreenScheme, :count).by(-1)
    end
  end
end
