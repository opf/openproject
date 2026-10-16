# frozen_string_literal: true

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

module WikiPages
  class FormFooterComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include ApplicationHelper
    include WikiHelper

    def initialize(page:, project:, form_identifier:, create:)
      super
      @page = page
      @project = project
      @form_identifier = form_identifier
      @create = create
    end

    def call
      render(StepWizard::FooterComponent.new(form_identifier: @form_identifier, total_steps: 1, current_step: 1)) do |footer|
        footer.with_cancel_button(href: cancel_button_href, data: { turbo_confirm: I18n.t(:text_are_you_sure) })
        footer.with_submit_button(**submit_button_args)
      end
    end

    private

    def cancel_button_href
      wiki_page_cancel_href(@page, @project)
    end

    def submit_button_args
      {
        form: @form_identifier,
        label: @create ? t(:button_create) : t(:button_save),
        name: :save
      }
    end
  end
end
