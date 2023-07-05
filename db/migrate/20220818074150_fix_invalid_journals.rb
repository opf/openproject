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

class FixInvalidJournals < ActiveRecord::Migration[7.0]
  def up
    get_broken_journals.each do |journable_type, relation|
      next unless relation.any?

      # rubocop:disable Rails/Output
      puts "Cleaning up broken journals on #{journable_type}"
      # rubocop:enable Rails/Output
      relation.destroy_all
    end
  end

  def down
    # nothing to do
  end

  def get_broken_journals
    Journal
      .pluck('DISTINCT(journable_type)')
      .compact
      .to_h do |journable_type|
      journal_class = journable_type.constantize.journal_class

      relation = Journal
        .where(journable_type:)
        .where.not(data_type: journal_class.to_s)

      [journable_type, relation]
    end
  end
end
