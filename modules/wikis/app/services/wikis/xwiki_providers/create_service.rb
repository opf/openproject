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
  module XWikiProviders
    class CreateService < ::BaseServices::Create
      private

      def after_validate(service_call)
        call = super
        return call unless call.success?

        provider = call.result
        if provider.configured_from_env?
          fetch_id_later! unless explicit_uid?
        else
          fetch_id_now(provider, call)
        end

        call
      end

      def after_persist(_call)
        call = super
        return call unless call.success?

        XWikiProviders::FetchInstanceIdJob.perform_later(call.result) if fetch_id_later?

        call
      end

      def fetch_id_now(provider, call)
        result = Wikis::XWikiProviders::FetchInstanceIdService.new(provider:).call
        if result.success?
          provider.universal_identifier = result.value!
        else
          call.errors.add(:url, :wiki_provider_unreachable)
          call.success = false
        end
      end

      # In cases where we can't expect the id fetching to work immediately, we'll queue a job that will do it
      # asynchronously "later". This is mostly the case when creating the provider during seeding, when the corresponding
      # XWiki instance might not be running yet
      def fetch_id_later!
        @fetch_id_later = true
      end

      def fetch_id_later?
        @fetch_id_later
      end

      def explicit_uid?
        params.key?(:universal_identifier)
      end
    end
  end
end
