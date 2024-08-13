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

module Bim::Bcf
  module Viewpoints
    class SetAttributesService < ::BaseServices::SetAttributes
      private

      def set_attributes(params)
        super

        set_snapshot
      end

      def set_default_attributes(_params)
        viewpoint["guid"] = model.uuid
      end

      def set_snapshot
        return unless snapshot_data_complete? && snapshot_content_type

        name = "snapshot.#{snapshot_extension}"
        file = OpenProject::Files
                 .create_uploaded_file(name:,
                                       content_type: snapshot_content_type,
                                       content: snapshot_binary_contents,
                                       binary: true)

        # This might break once the service is also used
        # to update existing viewpoints as the snapshot method will
        # delete any existing snapshot right away while the expectation
        # on a SetAttributesService is to not perform persisted changes.
        model.snapshot&.mark_for_destruction
        model.build_snapshot file, user:
      end

      def snapshot_data_complete?
        viewpoint["snapshot"] &&
          snapshot_extension &&
          snapshot_base64
      end

      def snapshot_content_type
        # Return nil when the extension is not within the specified set
        # which will lead to the snapshot not being created.
        # The contract will catch the error.
        return unless viewpoint["snapshot"]

        case viewpoint["snapshot"]["snapshot_type"]
        when "png"
          "image/png"
        when "jpg"
          "image/jpeg"
        end
      end

      def snapshot_extension
        viewpoint["snapshot"]["snapshot_type"]
      end

      def snapshot_base64
        viewpoint["snapshot"]["snapshot_data"]
      end

      def snapshot_binary_contents
        if snapshot_base64.include?("base64,")
          Base64.decode64(snapshot_base64.split("base64,").last)
        else
          Base64.decode64(snapshot_base64)
        end
      end

      def viewpoint
        model.json_viewpoint
      end
    end
  end
end
