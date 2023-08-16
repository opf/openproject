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

module OpTurbo
  module ComponentStream
    extend ActiveSupport::Concern

    included do
      before_action :initialize_streams
    end

    def initialize_streams
      @turbo_streams = []
    end

    def respond_to_with_turbo_streams(&format_block)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: @turbo_streams
        end

        format_block.call(format) if block_given?
      end
    end
    alias_method :respond_with_turbo_streams, :respond_to_with_turbo_streams

    def update_via_turbo_stream(component:)
      modify_via_turbo_stream(component:, action: :update)
    end

    def replace_via_turbo_stream(component:)
      modify_via_turbo_stream(component:, action: :replace)
    end

    def remove_via_turbo_stream(component:)
      modify_via_turbo_stream(component:, action: :remove)
    end

    def modify_via_turbo_stream(component:, action:)
      @turbo_streams << component.render_as_turbo_stream(
        view_context:,
        action:
      )
    end

    def append_via_turbo_stream(component:, target_component:)
      @turbo_streams << target_component.insert_as_turbo_stream(component:, view_context:, action: :append)
    end

    def prepend_via_turbo_stream(component:, target_component:)
      @turbo_streams << target_component.insert_as_turbo_stream(component:, view_context:, action: :prepend)
    end
  end
end
