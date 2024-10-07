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
#
module Saml::Providers::Sections
  class FormComponent < SectionComponent
    attr_reader :edit_state, :next_edit_state, :edit_mode

    def initialize(provider, edit_state:, form_class:,
                   heading:, banner: nil, banner_scheme: :default,
                   next_edit_state: nil, edit_mode: nil)
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
        saml_providers_path(edit_state:, edit_mode:, next_edit_state:)
      else
        saml_provider_path(provider, edit_state:, edit_mode:, next_edit_state:)
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
      if edit_mode
        I18n.t(:button_continue)
      else
        I18n.t(:button_update)
      end
    end
  end
end
