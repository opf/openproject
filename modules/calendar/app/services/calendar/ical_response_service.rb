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

module Calendar
  class ICalResponseService < ::BaseServices::BaseCallable
    include Contracted

    def initialize(*args)
      super
      self.contract_class = Queries::ICalSharingContract
    end

    def perform(ical_token_string:, query_id:)
      ical_token_instance = resolve_ical_token(ical_token_string)

      user = ical_token_instance.user
      query = Query.find(query_id)

      ical_string = nil

      User.execute_as(user) do
        success, errors = validate_and_yield(query, user, options: { ical_token: ical_token_instance }) do
          ical_string = ical_generation(query, user)
        end

        ServiceResult.new(success:, result: ical_string, errors:)
      end
    end

    protected

    def resolve_ical_token(ical_token_string)
      call = ::Calendar::ResolveICalTokenService.new.call(
        ical_token_string:
      )
      ical_token_instance = call.result if call.success?

      ical_token_instance
    end

    def ical_generation(query, user)
      User.execute_as(user) do
        work_packages = resolve_work_packages(query)
        create_ical_string(work_packages, query.name)
      end
    end

    def resolve_work_packages(query)
      call = ::Calendar::ResolveWorkPackagesService.new.call(
        query:
      )
      work_packages = call.result if call.success?

      work_packages
    end

    def create_ical_string(work_packages, calendar_name)
      call = ::Calendar::CreateICalService.new.call(
        work_packages:, calendar_name:
      )
      ical_string = call.result if call.success?

      ical_string
    end
  end
end
