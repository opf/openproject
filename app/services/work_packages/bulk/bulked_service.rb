#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module WorkPackages
  module Bulk
    class BulkedService
      include ::Shared::ServiceContext
      include ::HookHelper

      attr_accessor :user, :work_packages

      def initialize(user:, work_packages:)
        self.user = user
        self.work_packages = work_packages
      end

      def call(params)
        # This is not an all or nothing service. We currently accept that
        # one work package might be moved while another one fails.
        # Personally, I'd rather wrap it in a transaction.
        send_notifications = params[:send_notification] == '1'
        without_context_transaction(send_notifications:) do
          bulk(params)
        end
      end

      private

      def bulk(params)
        result = ServiceResult.success result: true

        work_packages.each do |work_package|
          # As updating one work package might have already saved another one,
          # e.g. by changing the start/due date or the version
          # we need to reload the work packages to avoid running into stale object errors.
          work_package.reload

          call_move_hook(work_package, params)

          result.add_dependent!(alter_work_package(work_package, params))
        end

        result.result = false if result.failure?

        result
      end

      def alter_work_package(_work_package, _params)
        raise NotImplementedError
      end

      def call_move_hook(_work_package, _params)
        raise NotImplementedError
      end
    end
  end
end
