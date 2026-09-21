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

RSpec.describe WorkPackage, with_ee: %i[work_package_trash] do
  let!(:active) { create(:work_package) }
  let!(:trashed) { create(:work_package, deleted_at: Time.current, deletion_group: SecureRandom.uuid) }

  it "excludes trashed records from the active scope" do
    expect(described_class.active.where(id: [active.id, trashed.id])).to contain_exactly(active)
  end

  it "makes trashed records explicitly available" do
    expect(described_class.trashed).to contain_exactly(trashed)
  end
end
