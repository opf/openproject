#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Grids
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
          next unless @errors.empty?

          {
            href: resource_url,
            method: commit_method
          }
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
          GridPayloadRepresenter
            .new(represented, current_user: current_user)
        end

        def schema_representer
          contract = contract_class.new(represented, current_user)

          API::V3::Grids::Schemas::GridSchemaRepresenter.new(contract,
                                                             form_embedded: true,
                                                             current_user: current_user)
        end

        def contract_class
          raise NotImplementedError, "subclass responsibility"
        end
      end
    end
  end
end
