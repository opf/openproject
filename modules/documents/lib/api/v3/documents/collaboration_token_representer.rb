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
    module Documents
      ##
      # Renders a freshly issued collaboration token for a document.
      #
      # Deliberately not a cached representer: the token is specific to the requesting user
      # and must never be served to anybody else.
      class CollaborationTokenRepresenter < ::API::Decorators::Single
        CollaborationToken = Data.define(:document, :token, :document_name, :expires_at, :expires_in_seconds) do
          def self.from_token_result(document, token_result)
            new(document:,
                token: token_result[:encrypted_token],
                document_name: token_result[:resource_url],
                expires_at: token_result[:expires_at],
                expires_in_seconds: token_result[:expires_in_seconds])
          end
        end

        link :document do
          {
            href: api_v3_paths.document(represented.document.id),
            title: represented.document.title
          }
        end

        link :createCollaborationToken do
          {
            href: api_v3_paths.document_collaboration_token(represented.document.id),
            method: :post
          }
        end

        link :collaborationServer do
          {
            href: Setting.collaborative_editing_hocuspocus_url
          }
        end

        property :token

        property :document_name

        property :expires_at

        property :expires_in_seconds

        def _type
          "CollaborationToken"
        end
      end
    end
  end
end
