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

module API
  module V3
    module Collaboration
      # The collaboration server derives read-only access from the presence of the update link
      # and loads the Y.Doc from contentBinary.
      # Must be included after API::Caching::CachedRepresenter, which provides `link` with `cache_if`.
      module CollaborativeContentRepresenter
        extend ActiveSupport::Concern

        included do
          link :update,
               cache_if: -> { represented.collaboration_editable_by?(current_user) } do
            {
              href: represented.collaboration_api_path,
              method: :patch
            }
          end

          property :content_binary
        end
      end
    end
  end
end
