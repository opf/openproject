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

require_relative "../spec_helper"

RSpec.describe Whiteboard do
  let(:project) { create(:project, enabled_module_names: %w[whiteboards]) }
  let(:whiteboard) { create(:whiteboard, project:) }
  let(:viewer) { create(:user, member_with_permissions: { project => %i[view_whiteboards] }) }
  let(:editor) { create(:user, member_with_permissions: { project => %i[view_whiteboards manage_whiteboards] }) }

  describe "#collaboration_resource_url" do
    it "points to the whiteboard API resource" do
      expect(whiteboard.collaboration_resource_url).to end_with("/api/v3/whiteboards/#{whiteboard.id}")
    end
  end

  describe "#collaboration_readonly_for?" do
    it "is read-only for users who can only view" do
      expect(whiteboard.collaboration_readonly_for?(viewer)).to be true
    end

    it "is writable for users who can manage" do
      expect(whiteboard.collaboration_readonly_for?(editor)).to be false
    end
  end

  describe ".visible" do
    let!(:other_whiteboard) { create(:whiteboard) }

    it "only contains whiteboards of projects the user may view" do
      whiteboard
      expect(described_class.visible(viewer)).to contain_exactly(whiteboard)
      expect(described_class.visible(viewer)).not_to include(other_whiteboard)
    end
  end
end
