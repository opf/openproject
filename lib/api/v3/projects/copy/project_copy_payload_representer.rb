#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Projects
      module Copy
        class ProjectCopyPayloadRepresenter < ::API::V3::Projects::ProjectRepresenter
          include ::API::Utilities::PayloadRepresenter

          cached_representer disabled: true

          # Use this to create our own representers, giving them a chance to override the instantiation
          # if desired.
          def self.create(model, current_user:, service_call: nil, embed_links: false)
            new(model, current_user: current_user, service_call: service_call, embed_links: embed_links)
          end

          attr_reader :service_call

          def initialize(model, current_user:, service_call: nil, embed_links: false)
            @service_call = service_call
            super(model, current_user: current_user, embed_links: embed_links)
          end

          property :_meta,
                   exec_context: :decorator,
                   getter: ->(*) { ProjectCopyMetaRepresenter.create(meta_object, current_user: current_user) },
                   # TODO how to handle parsing nested _meta into something else?
                   setter: ->(fragment:, **) do
                     only = Set.new
                     Hash(fragment)
                       .transform_keys { |key| key.underscore.gsub('copy_', '') }
                       .each do |key, checked|
                       only << key.to_sym if checked
                     end

                     represented.only = only
                   end

          private

          def meta_object
            service_call&.state || OpenStruct.new
          end
        end
      end
    end
  end
end
