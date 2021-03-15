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
    module Capabilities
      class CapabilitiesAPI < ::API::OpenProjectAPI
        resources :capabilities do
          helpers API::Utilities::PageSizeHelper

          get do
            ::API::V3::Utilities::SqlRepresenterWalker
              .new(::Queries::Capabilities::CapabilityQuery.new(user: current_user).results,
                   embed: { 'elements' => {} },
                   select: { 'elements' => { 'id' => {}, '_type' => {}, 'self' => {}, 'context' => {}, 'principal' => {} } },
                   current_user: current_user,
                   page_size: params[:pageSize],
                   offset: params[:offset])
              .walk(API::V3::Capabilities::CapabilitySqlCollectionRepresenter)
          end

          params do
            requires :namespace, type: String, desc: 'The action namespace identifier'
            requires :action, type: String, desc: 'The action identifier'
            requires :context, type: String, desc: 'The context identifier'
            requires :principal, type: Integer, desc: 'The principal identifier'
          end
          namespace ':namespace/:action/:context-:principal' do
            after_validation do

            end

            get do
              ::API::V3::Utilities::SqlRepresenterWalker
                .new(::Queries::Capabilities::CapabilityQuery.new(user: current_user).results.limit(1),
                     embed: { },
                     select: { 'id' => {}, '_type' => {}, 'self' => {}, 'context' => {}, 'principal' => {} },
                     current_user: current_user)
                .walk(API::V3::Capabilities::CapabilitySqlRepresenter)
            end
          end


          namespace :contexts do
            mount API::V3::Capabilities::Contexts::GlobalAPI
          end
        end
      end
    end
  end
end
