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

module OpenProject::TextFormatting::Formats
  class BaseFormat
    class << self
      def format
        raise NotImplementedError
      end

      def priority
        raise NotImplementedError
      end

      def helper
        @helper = "OpenProject::TextFormatting::Formats::#{format.to_s.camelcase}::Helper".constantize
      end

      def formatter
        @formatter ||= "OpenProject::TextFormatting::Formats::#{format.to_s.camelcase}::Formatter".constantize
      end

      def setup
        # Force lookup to avoid const errors later on.
        helper and formatter
      rescue NameError => e
        Rails.logger.error "Failed to register wiki formatting #{format}: #{e}"
        Rails.logger.debug { e.backtrace }
      end
    end
  end
end
