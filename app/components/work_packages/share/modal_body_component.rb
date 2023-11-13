#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  module Share
    class ModalBodyComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include WorkPackages::Share::Concerns::Authorization

      def initialize(work_package:)
        super

        @work_package = work_package
      end

      def self.wrapper_key
        "work_package_share_list"
      end

      private

      def insert_target_modified?
        true
      end

      def insert_target_modifier_id
        'op-share-wp-active-shares'
      end

      def shared_principals
        @shared_principals ||= Principal
                                .having_entity_membership(@work_package)
                                .includes(work_package_shares: :roles)
                                .where(work_package_shares: { entity: @work_package })
                                .merge(MemberRole.only_non_inherited)
                                .ordered_by_name
      end
    end
  end
end
