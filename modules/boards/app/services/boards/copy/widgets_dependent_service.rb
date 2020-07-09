#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module Boards::Copy
  class WidgetsDependentService < ::Copy::Dependency
    protected

    def copy_dependency(params:)
      copy_widgets(source, target, params)
    end

    def copy_widgets(board, new_board, params)
      board.widgets.find_each do |widget|
        unless widget.identifier == 'work_package_query'
          raise "Expected widget work_package_query, got #{widget.identifier}"
        end

        new_widget = duplicate_widget(widget, new_board, params)

        if new_widget && !new_widget.save
          add_error!(new_widget, new_widget.errors)
        end
      end
    end

    def duplicate_widget(widget, new_board, params)
      new_widget = widget.dup
      new_widget.grid = new_board

      query = Query.find widget.options['queryId']

      call = ::Queries::CopyService
        .new(user: user, source: query)
        .with_state(state)
        .call(params)

      if call.success?
        new_widget.options['queryId'] = call.result.id.to_s
        new_widget
      else
        add_error! widget, call.errors
        nil
      end
    end
  end
end
