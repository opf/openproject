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

module Projects::Copy
  class BoardsDependentService < Dependency
    def self.human_name
      I18n.t(:'boards.label_boards')
    end

    def source_count
      ::Boards::Grid.where(project: source).count
    end

    protected

    # Copies boards from +project+
    # Only includes the queries visible in the wp table view.
    def copy_dependency(params)
      ::Boards::Grid.where(project: source).find_each do |board|
        duplicate_board(board, params)
      end
    end

    def duplicate_board(board, params)
      ::Boards::CopyService
        .new(source: board, user:)
        .with_state(state)
        .call(params.merge)
        .tap { |call| result.merge!(call, without_success: true) }
    end
  end
end
