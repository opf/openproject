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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module Errors
    class InternalError < ErrorBase
      identifier "InternalServerError"
      code 500

      def initialize(error_message = nil, exception: nil, **)
        error = I18n.t("api_v3.errors.code_500")

        if error_message && visible_exception?(exception)
          error += " #{error_message}"
        end

        super(error)
      end

      private

      ##
      # Hide internal database errors in production
      def visible_exception?(exception)
        exception_blacklist.none? do |clz|
          exception.is_a?(clz)
        end
      end

      def exception_blacklist
        [
          ActiveRecord::StatementInvalid
        ]
      end
    end
  end
end
