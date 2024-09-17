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

module OpPrimer
  module FormHelpers
    # Renders an inline form without needing a dedicated form class.
    #
    # This method dynamically creates a form class based on the provided block
    # and renders it. The form is instantiated with the provided form builder
    # which comes from a `primer_form_with` call.
    #
    # It is meant to avoid boilerplate classes for simple forms.
    #
    # @example
    #   primer_form_with(action: :update) do |form_builder|
    #     render_inline_form(form_builder) do |form|
    #       form.text_field(
    #         name: :ultimate_answer,
    #         label: "Ultimate answer",
    #         required: true,
    #         caption: "The answer to life, the universe, and everything"
    #       )
    #       form.submit(name: :submit, label: "Submit")
    #     end
    #   end
    #
    # @param form_builder [Object] The form builder object to be used for the form.
    # @param blk [Proc] A block that defines the form structure.
    def render_inline_form(form_builder, &blk)
      form_class = Class.new(ApplicationForm) do
        form(&blk)
      end
      render(form_class.new(form_builder))
    end

    # Renders an inline settings form without needing a dedicated form class.
    #
    # This method dynamically creates a form class based on the provided block
    # and renders it. The form is instantiated with the provided form builder
    # which comes from a `primer_form_with` call, and decorated with the
    # `settings_form` method.
    #
    # The settings form is providing helpers to render settings in a standard
    # way by reading their value, rendering labels from their name, and checking
    # if they are writable.
    #
    # It is meant to avoid boilerplate code.
    #
    # @example
    #   primer_form_with(action: :update) do |f|
    #     render_inline_settings_form(f) do |form|
    #       form.text_field(name: :attachment_max_size)
    #       form.radio_button_group(
    #         name: "work_package_done_ratio",
    #         values: WorkPackage::DONE_RATIO_OPTIONS
    #       )
    #       form.submit
    #     end
    #   end
    #
    # @param form_builder [Object] The form builder object to be used for the form.
    # @param blk [Proc] A block that defines the form structure.
    def render_inline_settings_form(form_builder, &blk)
      form_class = Class.new(ApplicationForm) do
        settings_form(&blk)
      end
      render(form_class.new(form_builder))
    end
  end
end
