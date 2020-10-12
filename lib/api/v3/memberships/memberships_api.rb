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
  module V3
    module Memberships
      class MembershipsAPI < ::API::OpenProjectAPI
        helpers ::API::Utilities::PageSizeHelper

        resources :memberships do
          get &::API::V3::Utilities::Endpoints::Index.new(model: Member,
                                                          scope: -> { Member.includes(MembershipRepresenter.to_eager_load) },
                                                          api_name: 'Membership')
                                                     .mount

          post &::API::V3::Utilities::Endpoints::Create.new(model: Member,
                                                            api_name: 'Membership')
                                                       .mount

          mount ::API::V3::Memberships::AvailableProjectsAPI
          mount ::API::V3::Memberships::Schemas::MembershipSchemaAPI
          mount ::API::V3::Memberships::CreateFormAPI

          route_param :id, type: Integer, desc: 'Member ID' do
            after_validation do
              @member = ::Queries::Members::MemberQuery
                        .new(user: current_user)
                        .results
                        .find(params['id'])
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: Member,
                                                           api_name: 'Membership')
                                                      .mount

            patch &::API::V3::Utilities::Endpoints::Update.new(model: Member,
                                                               api_name: 'Membership')
                                                          .mount

            delete &::API::V3::Utilities::Endpoints::Delete.new(model: Member)
                                                           .mount

            mount ::API::V3::Memberships::UpdateFormAPI
          end
        end
      end
    end
  end
end
