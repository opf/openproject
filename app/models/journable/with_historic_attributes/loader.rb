# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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

class Journable::WithHistoricAttributes
  class Loader
    def initialize(journables)
      @journables = Array(journables)
    end

    def journable_at_timestamp(journable, timestamp)
      at_timestamp(timestamp)[journable&.id]
    end

    def at_timestamp(timestamp)
      @at_timestamp ||= Hash.new do |h, t|
        h[t] = (currently_invisible_journalized_at_timestamp(t) + currently_visible_journalized_at_timestamp(t)).index_by(&:id)
      end

      @at_timestamp[timestamp]
    end

    def work_package_ids_of_query_at_timestamp(query:, timestamp: nil)
      @work_package_ids_of_query_at_timestamp ||= Hash.new do |qh, q|
        qh[q] = Hash.new do |th, t|
          th[t] = work_package_ids_of_query_at_timestamp_calculation(q, t)
        end
      end

      @work_package_ids_of_query_at_timestamp[query][timestamp]
    end

    private

    def work_package_ids_of_query_at_timestamp_calculation(query, timestamp)
      query = query.dup
      query.timestamps = [timestamp] if timestamp

      query.results.work_packages.where(id: journables.map(&:id)).pluck(:id)
    end

    def currently_visible_journables
      @currently_visible_journables ||= begin
        visible_ids = journalized_class.visible.where(id: journables.map(&:id)).pluck(:id)
        journables.select { |j| visible_ids.include?(j.id) }
      end
    end

    def currently_invisible_journables
      @currently_invisible_journables ||= journables - currently_visible_journables
    end

    def currently_invisible_journalized_at_timestamp(timestamp)
      journalized_class.visible.at_timestamp(timestamp).where(id: currently_invisible_journables)
    end

    def currently_visible_journalized_at_timestamp(timestamp)
      journalized_class.at_timestamp(timestamp).where(id: currently_visible_journables)
    end

    def journalized_class
      journables.first.class
    end

    attr_accessor :journables
  end
  private_constant :Loader
end
