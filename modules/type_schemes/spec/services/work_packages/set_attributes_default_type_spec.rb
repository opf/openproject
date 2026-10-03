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

RSpec.describe WorkPackages::SetAttributesService, "default type with type schemes" do
  shared_let(:epic)  { create(:type) }
  shared_let(:story) { create(:type) }
  shared_let(:bug)   { create(:type) }
  shared_let(:project) { create(:project, types: [epic, story, bug]) }
  shared_let(:user) { create(:admin) }

  def default_type_for(project)
    wp = WorkPackage.new
    described_class.new(user:, model: wp, contract_class: WorkPackages::CreateContract).call(project:)
    wp.type
  end

  it "has a native default that differs from the scheme default" do
    expect(project.enabled_types.first).not_to eq(story)
  end

  context "with an active scheme whose default is story" do
    before { ProjectTypeScheme.create!(project:, scheme: create(:type_scheme, types: [story, epic])) }

    it "uses the scheme default" do
      expect(default_type_for(project)).to eq(story)
    end
  end

  context "without a scheme" do
    it "keeps the native default" do
      expect(default_type_for(project)).to eq(project.enabled_types.first)
    end
  end

  context "with an inactive scheme" do
    before do
      scheme = create(:type_scheme, types: [story, epic])
      ProjectTypeScheme.create!(project:, scheme:)
      scheme.update_columns(active: false)
    end

    it "keeps the native default" do
      expect(default_type_for(project)).to eq(project.enabled_types.first)
    end
  end
end
