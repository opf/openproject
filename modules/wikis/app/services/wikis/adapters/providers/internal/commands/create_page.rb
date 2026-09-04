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
                if input_data.wiki_parent?
                  create_root_page(input_data, user:)
                else
                  create_child_page(input_data, user:)
                end
              end
            end

            private

            def create_root_page(input_data, user:)
              wiki = Wiki.find_by(id: input_data.parent_identifier)
              return failure(code: :not_found) unless wiki&.visible?(user)

              create_page(title: input_data.title, wiki:, parent: nil, user:)
            end

            def create_child_page(input_data, user:)
              parent = WikiPage.visible(user).find_by(id: input_data.parent_identifier)
              return failure(code: :not_found) if parent.nil?

              create_page(title: input_data.title, wiki: parent.wiki, parent:, user:)
            end

            def create_page(title:, wiki:, parent:, user:)
              service_result_to_monad(::WikiPages::CreateService.new(user:).call(title:, parent:, wiki:))
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
