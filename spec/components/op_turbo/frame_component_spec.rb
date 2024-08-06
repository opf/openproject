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
#
require "spec_helper"

RSpec.describe OpTurbo::FrameComponent, type: :component do
  describe "#turbo_frame_id" do
    context "with `context:` option" do
      it "returns the turbo frame id" do
        storage = build_stubbed(:nextcloud_storage, id: 1)
        component = described_class.new(storage, context: :general_info)

        expect(component.turbo_frame_id).to eq("general_info_storages_nextcloud_storage_1")
      end
    end

    context "without `context:` option" do
      it "returns just the model dom id" do
        storage = build_stubbed(:nextcloud_storage, id: 1)
        component = described_class.new(storage)

        expect(component.turbo_frame_id).to eq("storages_nextcloud_storage_1")
      end
    end

    context "with `id:` option" do
      it "returns the turbo frame id" do
        component = described_class.new(id: "test_id")

        expect(component.turbo_frame_id).to eq("test_id")
      end
    end

    context "with `id:` and `context:` option" do
      it "returns the turbo frame id" do
        component = described_class.new(id: "test_id", context: :general_info)

        expect(component.turbo_frame_id).to eq("general_info_test_id")
      end
    end
  end
end
