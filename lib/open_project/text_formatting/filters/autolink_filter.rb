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

module OpenProject::TextFormatting
  module Filters
    # HTML Filter for auto_linking urls in HTML.
    #
    # Context options:
    #
    #   autolink:
    #     classes: (string) Classes to add to auto linked urls and mails
    #     enabled: (boolean)
    #
    # This filter does not write additional information to the context.
    class AutolinkFilter < HTML::Pipeline::Filter
      def call
        autolink_context = default_autolink_options.merge context.fetch(:autolink, {})
        return doc if autolink_context[:enabled] == false

        ::Rinku.auto_link(html, :all, "class=\"#{autolink_context[:classes]}\" rel=\"noopener noreferrer\"", nil,
                          Rinku::AUTOLINK_SHORT_DOMAINS)
      end

      def default_autolink_options
        {
          enabled: true,
          # Having to specify the link class again here is unfortunate. But as rinku seems to run latest,
          # it cannot receive the link class like all the rest of the links.
          classes: "op-uc-link"
        }
      end
    end
  end
end
