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

module ::Bim
  module Menus
    class DefaultQueryGeneratorService
      DEFAULT_QUERY = :all_open

      QUERY_OPTIONS = [
        DEFAULT_QUERY,
        :latest_activity,
        :recently_created,
        :created_by_me,
        :assigned_to_me
      ].freeze

      def call(query_key: DEFAULT_QUERY)
        params = self.class.assign_params(query_key)

        return if params.nil?

        { query_props: params.to_json, name: query_key }
      end

      class << self
        def all_open_query
          {
            c: %w[id subject bcfThumbnail type status assignee updatedAt],
            t: "id:desc"
          }
        end

        def latest_activity_query
          {
            c: %w[id subject bcfThumbnail type status assignee updatedAt],
            t: "updatedAt:desc",
            f: [{ "n" => "status", "o" => "o", "v" => [] }]
          }
        end

        def recently_created_query
          {
            c: %w[id subject bcfThumbnail type status assignee createdAt],
            t: "createdAt:desc",
            f: [{ "n" => "status", "o" => "o", "v" => [] }]
          }
        end

        def created_by_me_query
          {
            c: %w[id subject bcfThumbnail type status author updatedAt],
            t: "id:desc",
            f: [{ "n" => "status", "o" => "o", "v" => [] },
                { "n" => "author", "o" => "=", "v" => ["me"] }]
          }
        end

        def assigned_to_me_query
          {
            c: %w[id subject bcfThumbnail type status author updatedAt],
            t: "id:desc",
            f: [{ "n" => "status", "o" => "o", "v" => [] },
                { "n" => "assigneeOrGroup", "o" => "=", "v" => ["me"] }]
          }
        end

        def assign_params(query_key)
          case query_key
          when DEFAULT_QUERY
            all_open_query
          when :latest_activity
            latest_activity_query
          when :recently_created
            recently_created_query
          when :created_by_me
            return unless User.current.logged?

            created_by_me_query
          when :assigned_to_me
            return unless User.current.logged?

            assigned_to_me_query
          end
        end
      end
    end
  end
end
