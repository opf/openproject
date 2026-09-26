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

RSpec.describe WorkPackages::Import::CSV::Upload do
  subject(:upload) { described_class.create! }

  shared_let(:role) { create(:project_role, permissions: %i[import_work_packages]) }
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }

  let(:attachment) { create(:attachment, container: upload, author: user) }

  it "keeps its file out of the pool a work package description claims from" do
    expect(Attachments::ClaimableIdsFromText.call("/attachments/#{attachment.id}/content", user:))
      .to be_empty
  end

  it "counts as an internal container, so indexing and scanning are skipped" do
    expect(attachment).to be_internal_container
  end

  it "shows its file to the author and to nobody else, administrators included" do
    expect(attachment.visible?(user)).to be(true)
    expect(attachment.visible?(create(:admin))).to be(false)
  end

  it "takes its file with it when it goes" do
    attachment

    expect { upload.destroy }.to change(Attachment, :count).by(-1)
  end
end
