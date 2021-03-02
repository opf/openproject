#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++
require_relative '../common/modal'
require_relative '../ng_select_autocomplete_helpers'

module Components
  module Users
    class InviteUserModal < ::Components::Common::Modal
      include ::Components::NgSelectAutocompleteHelpers

      def autocomplete(query)
        select_autocomplete modal_element.find('.ng-select-container'),
                            query: query,
                            results_selector: 'body'
      end

      def select_type(type)
        within_modal do
          page.find('.op-option-list--item', text: type).click
        end
      end

      def next
        click_modal_button 'Next'
      end

      def invitation_message(text)
        within_modal do
          find('textarea').set text
        end
      end
    end
  end
end
