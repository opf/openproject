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
require Rails.root.join("db/migrate/20260312121938_initialize_historic_identifiers.rb")

RSpec.describe InitializeHistoricIdentifiers, type: :model do
  subject(:execute_migration) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  let!(:project1) { create(:project, identifier: "project-one") }
  let!(:project2) { create(:project, identifier: "project-two") }
  let!(:project3) { create(:project, identifier: "project-three") }

  it "succeeds" do
    expect { execute_migration }.not_to raise_error
  end

  it "creates entries with correct attributes" do
    execute_migration
    expect(FriendlyId::Slug.count).to be(3)

    slug1 = FriendlyId::Slug.find_by(sluggable_id: project1.id, sluggable_type: "Project")
    expect(slug1).to have_attributes(
      slug: "project-one",
      sluggable_id: project1.id,
      sluggable_type: "Project",
      scope: nil
    )

    slug2 = FriendlyId::Slug.find_by(sluggable_id: project2.id, sluggable_type: "Project")
    expect(slug2).to have_attributes(
      slug: "project-two",
      sluggable_id: project2.id,
      sluggable_type: "Project",
      scope: nil
    )

    slug3 = FriendlyId::Slug.find_by(sluggable_id: project3.id, sluggable_type: "Project")
    expect(slug3).to have_attributes(
      slug: "project-three",
      sluggable_id: project3.id,
      sluggable_type: "Project",
      scope: nil
    )
  end

  it "sets created_at timestamp" do
    execute_migration

    slug = FriendlyId::Slug.find_by(sluggable_id: project1.id, sluggable_type: "Project")
    expect(slug.created_at).to be_present
    expect(slug.created_at).to be_within(5.minutes).of(Time.zone.now)
  end
end
