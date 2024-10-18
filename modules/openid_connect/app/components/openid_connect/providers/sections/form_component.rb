# frozen_string_literal: true

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

module OpenIDConnect::Providers::Sections
  class FormComponent < ::Saml::Providers::Sections::SectionComponent
    attr_reader :edit_state, :next_edit_state, :edit_mode

    def initialize(provider,
                   edit_state:,
                   form_class:,
                   heading:,
                   banner: nil,
                   banner_scheme: :default,
                   next_edit_state: nil,
                   edit_mode: nil)
      super(provider)

      @edit_state = edit_state
      @next_edit_state = next_edit_state
      @edit_mode = edit_mode
      @form_class = form_class
      @heading = heading
      @banner = banner
      @banner_scheme = banner_scheme
    end

    def url
      if provider.new_record?
        openid_connect_providers_path(**form_url_params)
      else
        openid_connect_provider_path(provider, **form_url_params)
      end
    end

    def form_url_params
      if edit_mode
        { edit_state:, edit_mode:, next_edit_state: }
      else
        { edit_state: }
      end
    end

    def form_method
      if provider.new_record?
        :post
      else
        :put
      end
    end

    def button_label
      return I18n.t(:button_save) unless edit_mode

      if next_edit_state.nil?
        I18n.t(:button_finish_setup)
      else
        I18n.t(:button_continue)
      end
    end
  end
end
