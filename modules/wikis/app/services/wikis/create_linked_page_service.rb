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
  class CreateLinkedPageService
    include ServiceAsErrorSource
    include Dry::Monads[:result]

    attr_reader :provider, :user

    def initialize(provider:, user:)
      @provider = provider
      @user = user
    end

    def call(title:, parent_identifier:, linkable_type:, linkable_id:)
      create_page(title:, parent_identifier:).either(
        ->(info) do
          link_page(identifier: info.identifier, linkable_type:, linkable_id:)
        end,
        ->(error) do
          ServiceResult.failure(errors: ActiveModel::Errors.new(self)).tap do |result|
            error_target = error.code == :missing_token ? :base : :wiki_page
            result.errors.add(error_target, error.code)
          end
        end
      )
    end

    private

    def create_page(title:, parent_identifier:)
      provider.auth_strategy_for(user).bind do |auth_strategy|
        Adapters::Input::CreatePage.build(title:, parent_identifier:).bind do |input_data|
          provider.resolve("commands.create_page").call(input_data:, auth_strategy:)
        end
      end
    end

    def link_page(identifier:, linkable_type:, linkable_id:)
      create_service = RelationPageLinks::CreateService.new(user:)
      create_service.call(
        provider_id: provider.id,
        linkable_type:,
        linkable_id:,
        author_id: user.id,
        identifier:
      )
    end
  end
end
