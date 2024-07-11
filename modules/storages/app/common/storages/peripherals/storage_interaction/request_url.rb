# frozen_string_literal:true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Storages
  module Peripherals
    module StorageInteraction
      module RequestUrl
        Builder = ->(storage, *path_fragments) do
          host_uri = storage.uri

          ensure_sub_path = ->(fragment) { fragment.ends_with?("/") ? fragment : "#{fragment}/" }
          ensure_relative_path = ->(fragment) { fragment.starts_with?("/") ? fragment[1..] : fragment }

          ensure_fragments_are_relative_sub_paths = ->(fragments) do
            return nil if fragments.nil?

            fragments[..-2]
              .map(&ensure_sub_path)
              .push(fragments.last)
              .map(&ensure_relative_path)
          end

          URI.join(host_uri.origin,
                   ensure_sub_path.(host_uri.path),
                   *ensure_fragments_are_relative_sub_paths.(path_fragments))
             .to_s
        end
      end
    end
  end
end
