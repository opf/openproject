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
        module Concerns
          module XWikiRequest
            ACCEPT_HEADERS = { "Accept" => "application/json" }.freeze

            def self.included(base)
              base.prepend Prepended
              base.extend ClassMethods
            end

            module Prepended
              def call(**)
                catch(:xwiki_error) { super }
              end
            end

            module ClassMethods
              include Dry::Monads[:result]

              def fetch_json(json_hash, key)
                json_hash.fetch(key) { throw :xwiki_error, Failure(Results::Error.new(source: self, code: :invalid_response)) }
              end
            end

            private

            def authenticated(auth_strategy)
              Adapters::Authentication[auth_strategy].call do |http|
                yield http.with(headers: ACCEPT_HEADERS)
              end
            end

            def rest_url(path, query: nil)
              # TODO: we might be able to extract a common URL formatting helper from Storages::UrlBuilder
              url = "#{provider.url.chomp('/')}/rest/#{path.delete_prefix('/')}"
              return url if query.nil?

              "#{url}?#{query.to_query}"
            end

            def handle_response(response)
              return failure(code: :connection_error) if response.is_a?(HTTPX::ErrorResponse)

              case response
              in { status: 200..299 }
                begin
                  json = response.json
                rescue MultiJson::ParseError
                  return failure(code: :invalid_response)
                end

                yield json
              in { status: 401 | 403 }
                failure(code: :unauthorized)
              in { status: 404 }
                failure(code: :not_found)
              else
                failure(code: :request_failed)
              end
            end

            def fetch_json(json_hash, key)
              self.class.fetch_json(json_hash, key)
            end
          end
        end
      end
    end
  end
end
