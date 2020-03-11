#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Bim::Bcf
  module Viewpoints
    class SetAttributesService < ::BaseServices::SetAttributes
      def set_attributes(params)
        super

        set_snapshot
      end

      def set_default_attributes(_params)
        model.json_viewpoint['guid'] = model.uuid
      end

      def set_snapshot
        return unless snapshot_data_complete? && snapshot_content_type

        file = OpenProject::Files
          .create_uploaded_file(name: "snapshot.#{snapshot_extension}",
                                content_type: snapshot_content_type,
                                content: snapshot_binary_contents,
                                binary: true)

        # This might break once the service is also used
        # to update existing viewpoints as the snapshot method will
        # delete any existing snapshot right away while the expectation
        # on a SetAttributesService is to not perform persisted changes.
        model.snapshot = file
      end

      def snapshot_data_complete?
        model.json_viewpoint['snapshot'] &&
          snapshot_extension &&
          snapshot_base_64 &&
          snapshot_url_parts.length > 1
      end

      def snapshot_content_type
        # Return nil when the extension is not within the specified set
        # which will lead to the snapshot not being created.
        # The contract will catch the error.
        return unless model.json_viewpoint['snapshot']

        case model.json_viewpoint['snapshot']['snapshot_type']
        when 'png'
          'image/png'
        when 'jpg'
          'image/jpeg'
        end
      end

      def snapshot_extension
        model.json_viewpoint['snapshot']['snapshot_type']
      end

      def snapshot_base_64
        model.json_viewpoint['snapshot']['snapshot_data']
      end

      def snapshot_binary_contents
        Base64.decode64(snapshot_url_parts[2])
      end

      def snapshot_url_parts
        snapshot_base_64.match(/\Adata:([-\w]+\/[-\w\+\.]+)?;base64,(.*)/m) || []
      end
    end
  end
end
