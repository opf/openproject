#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
  module Decorators
    class SimpleForm < ::API::Decorators::Form
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
        payload_representer_class
          .create(represented, current_user: current_user)
      end

      def schema_representer
        contract = contract_class.new(represented, current_user)

        schema_representer_class
          .create(contract,
                  form_embedded: true,
                  current_user: current_user)
      end

      def contract_class
        raise NotImplementedError, "subclass responsibility"
      end

      def model
        raise NotImplementedError, "subclass responsibility"
      end

      private

      def model_name
        model.name.demodulize
      end

      def payload_representer_class
        "API::V3::#{model_name.pluralize}::#{model_name}PayloadRepresenter"
          .constantize
      end

      def schema_representer_class
        "API::V3::#{model_name.pluralize}::Schemas::#{model_name}SchemaRepresenter"
          .constantize
      end
    end
  end
end
