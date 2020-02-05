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
      class CreateFormAPI < ::API::OpenProjectAPI
        resource :form do
          after_validation do
            authorize :manage_members, global: true
          end

          post &::API::V3::Utilities::Endpoints::CreateForm.new(model: Member,
                                                                instance_generator: ->(params) {
                                                                  # This here is a hack to circumvent the strange
                                                                  # way roles are assigned to a member within 3 models.
                                                                  # As this is never saved, we do not have to care for
                                                                  # that elaborate process.
                                                                  # Doing this leads to the roles being displayed
                                                                  # in the payload.
                                                                  roles = if params[:role_ids]
                                                                            Array(Role.find_by(id: params.delete(:role_ids)))
                                                                          end || []

                                                                  Member.new(roles: roles)
                                                                },
                                                                api_name: 'Membership')
                                                           .mount
        end
      end
    end
  end
end
