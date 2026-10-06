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

require_relative "../../../spec_helper"

RSpec.describe Collaboration::OAuth::TokenWithMetadataService,
               with_settings: { collaborative_editing_hocuspocus_secret: "test_secret_for_encryption" } do
  subject(:result) { described_class.new(user:, resource: whiteboard).call.result }

  let(:project) { create(:project, enabled_module_names: %w[whiteboards]) }
  let(:whiteboard) { create(:whiteboard, project:) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_whiteboards] }) }

  it "issues a token for the whiteboard resource" do
    expect(result[:resource_url]).to end_with("/api/v3/whiteboards/#{whiteboard.id}")
  end

  it "marks users without manage permission as read-only" do
    expect(result[:readonly]).to be true
  end
end
