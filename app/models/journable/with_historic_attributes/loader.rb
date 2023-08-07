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
        h[t] = journalized_at_timestamp(t).index_by(&:id)
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

    def load_custom_values(journalized = journables)
      journal_ids = begin
        journalized.map(&:journal_id)
      rescue NoMethodError
        raise ArgumentError,
              'The provided journalized items do not have a journal_id included. ' \
              'Please load them via any of the Journable::Timestamps#at_timestamp method. ' \
              'ie: WorkPackage.at_timestamp(1.day.ago) or WorkPackage.find(1).at_timestamp(1.day.ago)'
      end

      customizable_journals_by_journal_id = load_customizable_journals_by_journal_id(journal_ids)

      journalized.each do |work_package|
        customizable_journals = Array(customizable_journals_by_journal_id[work_package.journal_id])
        set_custom_value_association_from_journal!(work_package:, customizable_journals:)
      end
      journalized
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

    def journalized_at_timestamp(tms)
      journalized = (currently_invisible_journalized_at_timestamp(tms) + currently_visible_journalized_at_timestamp(tms))
      load_custom_values(journalized)
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

    def load_customizable_journals_by_journal_id(journal_ids)
      Journal::CustomizableJournal
        .where(journal_id: journal_ids)
        .includes(:custom_field)
        .group_by(&:journal_id)
    end

    def set_custom_value_association_from_journal!(work_package:, customizable_journals:)
      # Build the associated customizable_journals as custom values, this way the historic work packages
      # will behave just as the normal ones. Additionally set the reverse customized association
      # on the custom_values that points to the work_package itself.
      historic_custom_values = customizable_journals.map do |customizable_journal|
        customizable_journal.as_custom_value(customized: work_package)
      end

      work_package.association(:custom_values).loaded!
      work_package.association(:custom_values).target = historic_custom_values
    end

    attr_accessor :journables
  end
  private_constant :Loader
end
