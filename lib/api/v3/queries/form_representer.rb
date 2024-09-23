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
    module Queries
      class FormRepresenter < ::API::Decorators::Form
        link :self do
          {
            href: form_url,
            method: :post
          }
        end

        link :validate do
          {
            href: form_url,
            method: :post
          }
        end

        link :commit do
          if allow_commit?
            {
              href: resource_url,
              method: commit_method
            }
          end
        end

        link :create_new do
          if allow_create_as_new?
            {
              href: api_v3_paths.queries,
              method: :post
            }
          end
        end

        def commit_action
          raise NotImplementedError, "subclass responsibility"
        end

        def commit_method
          raise NotImplementedError, "subclass responsibility"
        end

        def form_url
          raise NotImplementedError, "subclass responsibility"
        end

        def resource_url
          raise NotImplementedError, "subclass responsibility"
        end

        def payload_representer
          QueryPayloadRepresenter
            .new(represented, current_user:)
        end

        def schema_representer
          Schemas::QuerySchemaRepresenter.new(represented,
                                              form_embedded: true,
                                              current_user:)
        end

        def allow_commit?
          @errors.empty? && represented.name.present? && allow_save?
        end

        def allow_save?
          QueryPolicy.new(current_user).allowed? represented, commit_action
        end

        def allow_create_as_new?
          QueryPolicy.new(current_user).allowed? represented, :create_new
        end
      end
    end
  end
end
