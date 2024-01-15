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
module WorkPackages::Share
  class Invitee < ApplicationForm
    form do |user_invite_form|
      user_invite_form.user_autocompleter(
        name: :user_id,
        label: I18n.t('work_package.sharing.label_search'),
        visually_hide_label: true,
        data: { 'work-packages--share--user-limit-target': 'autocompleter' },
        autocomplete_options: {
          id: "op-share-wp-invite-autocomplete",
          placeholder: I18n.t('work_package.sharing.label_search_placeholder'),
          data: {
            'test-selector': 'op-share-wp-invite-autocomplete'
          },
          url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
          filters: [{ name: 'type', operator: '=', values: %w[User Group] },
                    { name: 'id', operator: '!', values: [::Queries::Filters::MeValue::KEY] },
                    { name: 'status', operator: '=', values: [Principal.statuses[:active], Principal.statuses[:invited]] }],
          searchKey: 'any_name_attribute',
          addTag: User.current.allowed_globally?(:create_user),
          addTagText: I18n.t('members.send_invite_to'),
          multiple: true,
          focusDirectly: true,
          appendTo: 'body',
          disabled: @disabled
        }
      )
    end

    def initialize(disabled: false)
      super()
      @disabled = disabled
    end
  end
end
