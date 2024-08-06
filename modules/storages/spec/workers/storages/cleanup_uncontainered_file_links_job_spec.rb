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
require_module_spec_helper

RSpec.describe Storages::CleanupUncontaineredFileLinksJob, type: :job do
  describe "#perform" do
    it "removes uncontainered file_links which are old enough" do
      grace_period = 10
      allow(OpenProject::Configuration)
        .to receive(:attachments_grace_period)
              .and_return(grace_period)

      expect(Storages::FileLink.count).to eq(0)

      uncontainered_old = create(:file_link,
                                 container_id: nil,
                                 container_type: nil,
                                 created_at: Time.current - grace_period.minutes - 1.second)
      uncontainered_young = create(:file_link,
                                   container_id: nil,
                                   container_type: nil)
      containered_old = create(:file_link,
                               container_id: 1,
                               created_at: Time.current - grace_period.minutes - 1.second)
      containered_young = create(:file_link,
                                 container_id: 1)

      expect(Storages::FileLink.count).to eq(4)

      described_class.new.perform

      expect(Storages::FileLink.count).to eq(3)
      file_link_ids = Storages::FileLink.pluck(:id).sort
      expected_file_link_ids = [uncontainered_young.id, containered_old.id, containered_young.id].sort
      expect(file_link_ids).to eq(expected_file_link_ids)
      expect(file_link_ids).not_to include(uncontainered_old.id)
    end
  end
end
