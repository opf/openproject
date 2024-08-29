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
require "fileutils"

module OpenProject
  module Assets
    class << self
      ##
      # Look up an asset in the manifest. If it does not exist,
      # return the chunk name itself.
      # Input: main.js
      # Output:
      #  - when in manifest: main.<hash>.js
      #  - when not in manifest: main.js
      def lookup_asset(unhashed_filename)
        name = unhashed_filename.to_s
        load_manifest.fetch(name, name)
      end

      def frontend_asset_path
        Rails.public_path.join("assets/frontend/")
      end

      def manifest_path
        Rails.root.join("config/frontend_assets.manifest.json")
      end

      def load_manifest
        @manifest ||= begin
          JSON.parse File.read(manifest_path)
        rescue StandardError => e
          Rails.logger.error "Failed to read frontend manifest file: #{e}."
          {}
        end
      end

      ##
      # Clear frontend asset path
      def clear!
        FileUtils.rm_rf frontend_asset_path
      end

      ##
      # Rebuilds the manifest file
      def rebuild_manifest!
        # Remove index html
        FileUtils.remove File.join(frontend_asset_path, "index2.html"), force: true

        # Create map of asset chunk name to current hash
        manifest = {}
        OpenProject::Assets.current_assets.each do |filename|
          md = filename.match /\A([^.]+)\.(\w+)\.(\w+)\z/

          # Non-hashed asset
          next if md.nil?

          chunk_name = "#{md[1]}.#{md[3]}"
          manifest[chunk_name] = filename
        end

        File.write(manifest_path, manifest.to_json)
      end

      def current_assets
        Dir.glob(OpenProject::Assets.frontend_asset_path + "*")
          .select { |f| File.file? f }
          .map { |f| File.basename(f) }
      end
    end
  end
end
