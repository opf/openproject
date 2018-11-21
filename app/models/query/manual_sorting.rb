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
#
module Query::ManualSorting
  extend ActiveSupport::Concern

  included do
    has_many :ordered_work_packages, dependent: :delete_all

    def ordered_work_packages=(ordered_ids)
      OrderedWorkPackage.transaction do
        OrderedWorkPackage.where(query_id: id).delete_all
        insert_ordered_ids!(ordered_ids)
      end
    end

    private

    ##
    # TODO: Use InsertManager when upgraded to Rails 5.2
    # since this code inserts single entries.
    def insert_ordered_ids!(ordered_ids)
      OrderedWorkPackage.create!(
        ordered_ids.each_with_index.map do |wp_id, position|
          {
            query_id: id,
            work_package_id: wp_id,
            position: position
          }
        end
      )
    end
  end
end
