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

module API
  module Decorators
    class Formattable < Single
      include OpenProject::TextFormatting

      def initialize(model, plain: false, object: nil)
        @format = if plain
                    OpenProject::TextFormatting::Formats.plain_format
                  else
                    OpenProject::TextFormatting::Formats.rich_format
                  end
        @object = object

        # Note: TextFormatting actually makes use of User.current, if it was possible to pass a
        # current_user explicitly, it would make sense to pass one here too.
        super(model, current_user: nil)
      end

      property :format,
               exec_context: :decorator,
               getter: ->(*) { @format },
               writable: false,
               render_nil: true
      property :raw,
               exec_context: :decorator,
               getter: ->(*) { represented },
               render_nil: true
      property :html,
               exec_context: :decorator,
               getter: ->(*) { to_html },
               writable: false,
               render_nil: true

      def to_html
        format_text(represented, format: @format, object: @object)
      end

      private

      def model_required?
        # the formatted string may also be nil, we are prepared for that
        false
      end
    end
  end
end
