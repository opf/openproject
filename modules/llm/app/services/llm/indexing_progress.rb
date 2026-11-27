# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Llm
  class IndexingProgress
    def initialize(semantic_index)
      @semantic_index = semantic_index
    end

    def total_count = @total_count ||= WorkPackage.count

    def indexed_count
      @indexed_count ||= embeddings.where(failed_at: nil).joins(:work_package)
                                   .where(embeddings_table[:work_package_updated_at].gteq(WorkPackage.arel_table[:updated_at]))
                                   .distinct.count(:work_package_id)
    end

    def failed_count = @failed_count ||= embeddings.where.not(failed_at: nil).distinct.count(:work_package_id)

    def pending_count = total_count - indexed_count - failed_count

    def done_count = indexed_count + failed_count

    def percentage(count)
      return 0 if total_count.zero?

      count * 100 / total_count
    end

    private

    attr_reader :semantic_index

    def embeddings = WorkPackageEmbedding.where(semantic_index:)

    def embeddings_table = WorkPackageEmbedding.arel_table
  end
end
