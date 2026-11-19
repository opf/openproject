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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::Assets do
  describe ".rebuild_manifest!" do
    let(:tmp_dir) { Pathname.new(Dir.mktmpdir) }
    let(:asset_dir) { tmp_dir.join("frontend").tap(&:mkpath) }
    let(:manifest_file) { tmp_dir.join("manifest.json") }
    let(:manifest) { JSON.parse(manifest_file.read) }

    before do
      allow(described_class).to receive_messages(frontend_asset_path: asset_dir, manifest_path: manifest_file)
    end

    after { FileUtils.remove_entry(tmp_dir) }

    it "maps the hashed service worker to its logical name" do
      FileUtils.touch(asset_dir.join("service-worker-ABCD1234.js"))

      described_class.rebuild_manifest!

      expect(manifest).to eq("service-worker.js" => "service-worker-ABCD1234.js")
    end

    it "leaves unhashed files out of the manifest" do
      FileUtils.touch(asset_dir.join("service-worker.js"))
      FileUtils.touch(asset_dir.join("main-ABCD1234.js"))

      described_class.rebuild_manifest!

      expect(manifest.keys).to eq(["main.js"])
    end
  end
end
