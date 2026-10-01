# frozen_string_literal: true

# -- copyright
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
# ++

module Users
  class UserStatusFilterComponent < OpPrimer::QuickFilter::SelectPanelComponent
    def initialize(query:)
      super(
        name: User.human_attribute_name(:status),
        query:,
        filter_key: :status,
        path_args: [:users]
      )

      status_counts.each do |status, count|
        with_item(label: "#{I18n.t(:"status_#{status}")} (#{count})", value: status)
      end
    end

    private

    def status_counts
      counts = User.user.group(:status).count

      Principal.statuses.except("deleted").keys.map do |status|
        [status, counts[status] || 0]
      end
    end
  end
end
