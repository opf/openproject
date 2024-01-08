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

module Users
  class SetAttributesService < ::BaseServices::SetAttributes
    include ::HookHelper

    private

    attr_accessor :pref

    def set_attributes(params)
      self.pref = params.delete(:pref)

      super(params)
    end

    def validate_and_result
      super.tap do |result|
        result.merge!(set_preferences) if pref.present?
      end
    end

    def set_default_attributes(params)
      # Assign values other than mail to new_user when invited
      assign_name_attributes_from_mail(params) if model.invited? && model.valid_attribute?(:mail)
      assign_default_language

      model.notification_settings.build unless model.notification_settings.any?
    end

    def set_preferences
      ::UserPreferences::SetAttributesService
        .new(user:, model: model.pref, contract_class: ::UserPreferences::UpdateContract)
        .call(pref)
    end

    # rubocop:disable Metrics/AbcSize
    def assign_name_attributes_from_mail(params)
      placeholder = placeholder_name(params[:mail])

      model.login = model.login.presence || params[:mail]
      model.firstname = model.firstname.presence || placeholder.first
      model.lastname = model.lastname.presence || placeholder.last
    end
    # rubocop:enable Metrics/AbcSize

    def assign_default_language
      model.language = model.language.presence || Setting.default_language
    end

    ##
    # Creates a placeholder name for the user based on their email address.
    # For the unlikely case that the local or domain part of the email address
    # are longer than 30 characters they will be trimmed to 27 characters and an
    # ellipsis will be appended.
    def placeholder_name(email)
      first, last = email.split('@').map { |name| trim_name(name) }

      [first, "@#{last}"]
    end

    def trim_name(name)
      if name.size > 30
        "#{name[0..26]}..."
      else
        name
      end
    end
  end
end
