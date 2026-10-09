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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpPrimer
  module FormHelpers
    # Renders an inline settings form without needing a dedicated form class.
    #
    # This method dynamically creates a form class based on the provided block
    # and renders it. The form is instantiated with the provided form builder
    # which comes from a `primer_form_with` call, and decorated with the
    # `settings_form` method.
    #
    # @see inline_settings_form
    def render_inline_settings_form(*, &)
      render(inline_settings_form(*, &))
    end

    # Creates an inline settings form without needing a dedicated form class.
    #
    # This method dynamically creates a form class based on the provided block.
    # The form is instantiated with the provided form builder which comes from a
    # `primer_form_with` call, and decorated with the `settings_form` method.
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
    def inline_settings_form(form_builder, &blk)
      form_class = Class.new(ApplicationForm) do
        # This is a workaround to make the form class aware of the template path
        # of the block that is passed to it.
        #
        # This avoids an annoying warning "Could not identify the template" from
        # original `base_template_path` method.
        define_singleton_method(:base_template_path) do
          blk.source_location.first
        end

        form do |f|
          yield Settings::FormObjectDecorator.new(f)
        end
      end
      form_class.new(form_builder)
    end

    # An extension of primers default `primer_form_with`
    # Renders a primer form with a special wrapper around to limit the width for
    # legibility.
    #
    # This method dynamically creates a container around the actual form.
    # All arguments and the content are simply passed through to the `primer_form_with` call
    #
    # It is meant for any settings pages like in administration or project
    # settings to have a unified look and feel for our users.
    #
    # @example
    #   settings_primer_form_with(scope: :settings, action: :update, method: :patch) do |form|
    #     render_inline_settings_form(form) do |f|
    #       f.check_box(name: :allow_tracking_start_and_end_times)
    #       f.check_box(name: :enforce_tracking_start_and_end_times)
    #
    #       f.submit
    #     end
    #   end
    #
    # @param kwargs [Hash] The arguments for the form
    # @param block [Proc] A block that defines the form structure.
    def settings_primer_form_with(**, &)
      render(Primer::BaseComponent.new(tag: :div, classes: "op-admin-settings-form-wrapper")) do
        primer_form_with(**, &)
      end
    end
  end
end
