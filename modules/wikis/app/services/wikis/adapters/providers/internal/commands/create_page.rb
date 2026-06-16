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
      module Internal
        module Commands
          class CreatePage < BaseCommand
            def call(input_data:, auth_strategy:)
              Adapters::Authentication[auth_strategy].call do |user|
                parent = find_parent(input_data.parent_identifier, user:)
                return failure(code: :not_found) if parent.nil?

                service_result_to_monad(
                  WikiPages::CreateService.new(user:).call(
                    title: input_data.title,
                    parent:,
                    wiki: parent.wiki
                  )
                )
              end
            end

            private

            def find_parent(identifier, user:)
              WikiPage.visible(user).find_by(id: identifier)
            end

            def service_result_to_monad(result)
              if result.success?
                success(Queries::PageInfo.wiki_page_to_page_info(result.result, provider:))
              elsif result.errors.details.values.flatten.any? { |e| e.fetch(:error) == :error_unauthorized }
                failure(code: :forbidden)
              else
                # for now simplifying to a single error code, since there is not really any
                # error case expected to crop up during real usage, due to previous validations in upstream code
                failure(code: :invalid)
              end
            end
          end
        end
      end
    end
  end
end
