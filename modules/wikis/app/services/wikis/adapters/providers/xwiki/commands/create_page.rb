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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  module Adapters
    module Providers
      module XWiki
        module Commands
          class CreatePage < BaseCommand
            include Concerns::XWikiRequest

            class << self
              # We have to manually derive a useful ID from the title that's both valid, but also makes for a nice XWiki URL
              def derive_page_id(title)
                title.tr("\\", "").gsub(/[.:]/, { ":" => "\\:", "." => "\\." })
              end
            end

            def call(input_data:, auth_strategy:)
              parent_result = fetch_canonical_parent(identifier: input_data.parent_identifier, auth_strategy:)
              parent_result.bind do |canonical_parent|
                identifier = "#{canonical_parent}.#{self.class.derive_page_id(input_data.title)}.WebHome"

                create_page_request(identifier, title: input_data.title, auth_strategy:) do |data|
                  success(Queries::StablePageInfo.json_to_page_info(data, provider:))
                end
              end
            end

            private

            def fetch_canonical_parent(identifier:, auth_strategy:)
              ref = StablePageReference.parse(identifier)
              return failure(code: :not_found) unless ref

              authenticated(auth_strategy) do |http|
                handle_response(http.get(rest_url(ref.rest_path))) do |data|
                  success("#{fetch_json(data, 'wiki')}:#{fetch_json(data, 'space')}")
                end
              end
            end

            def create_page_request(reference, title:, auth_strategy:, &)
              authenticated(auth_strategy) do |http|
                handle_response(
                  http.with(headers: { "Content-Type": "application/json" })
                      .put(rest_url("openproject/documents", query: { docRef: reference.to_s }), body: { title: }.to_json),
                  &
                )
              end
            end
          end
        end
      end
    end
  end
end
