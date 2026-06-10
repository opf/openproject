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

require "rails_helper"

RSpec.describe ProjectIdentifiers::ClassicIdentifierSuggestionGenerator do
  describe "#suggest_identifier" do
    subject(:generator) { described_class.new }

    it "slugifies the name" do
      expect(generator.suggest_identifier("My Project")).to eq("my-project")
    end

    it "appends -1 when the base slug is taken by an existing project identifier" do
      create(:project, identifier: "my-project")
      expect(described_class.new.suggest_identifier("My Project")).to eq("my-project-1")
    end

    it "increments the suffix until a free slot is found" do
      create(:project, identifier: "my-project")
      create(:project, identifier: "my-project-1")
      expect(described_class.new.suggest_identifier("My Project")).to eq("my-project-2")
    end

    it "avoids slugs reserved in FriendlyId history" do
      project = create(:project, identifier: "other-id")
      FriendlyId::Slug.create!(slug: "my-project", sluggable_type: "Project", sluggable_id: project.id)
      expect(described_class.new.suggest_identifier("My Project")).to eq("my-project-1")
    end

    it "avoids reserved identifiers, falling back to a suffixed version" do
      expect(described_class.new.suggest_identifier("New")).to eq("new-1")
    end

    context "when the name produces a blank slug" do
      it "falls back to a randomised project-XXXXXX identifier" do
        expect(described_class.new.suggest_identifier("!!!")).to match(/\Aproject-[a-z0-9]{5}\z/)
      end

      it "maps '.' to 'dot'" do
        expect(described_class.new.suggest_identifier(".")).to eq("dot")
      end

      it "maps '!' to 'bang'" do
        expect(described_class.new.suggest_identifier("!")).to eq("bang")
      end
    end

    context "when the name is all-numeric" do
      it "falls back to a randomised project-XXXXXX identifier" do
        expect(described_class.new.suggest_identifier("12345")).to match(/\Aproject-[a-z0-9]{5}\z/)
      end
    end
  end

  describe "#restore_identifier" do
    let(:project) { create(:project, identifier: "current-id") }

    before do
      project # ensure created before we travel

      travel_to(2.days.ago) { FriendlyId::Slug.create!(slug: "older-classic", sluggable_type: "Project", sluggable_id: project.id) }
      travel_to(1.day.ago)  { FriendlyId::Slug.create!(slug: "old-classic",   sluggable_type: "Project", sluggable_id: project.id) }
    end

    subject(:generator) { described_class.new(project:) }

    it "returns the most recent classic-format slug from history" do
      expect(generator.restore_identifier(project)).to eq("old-classic")
    end

    it "skips non-classic (e.g. uppercase semantic) slugs in history" do
      FriendlyId::Slug.create!(slug: "SEMANTIC1", sluggable_type: "Project", sluggable_id: project.id, created_at: 1.hour.ago)
      expect(generator.restore_identifier(project)).to eq("old-classic")
    end

    it "returns nil when history contains no classic-format slugs" do
      FriendlyId::Slug.where(sluggable_id: project.id).delete_all
      FriendlyId::Slug.create!(slug: "SEMANTIC1", sluggable_type: "Project", sluggable_id: project.id)
      expect(described_class.new(project:).restore_identifier(project)).to be_nil
    end
  end
end
