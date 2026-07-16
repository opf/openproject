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

module WorkPackageTypes
  # Mode chooser (Independent/Linked) + source picker, shared by the PDF and
  # subject tabs. When Independent, the tab's own editor (passed as the block
  # content) shows; picking Linked swaps it for the source picker + Save.
  # Toggling is client-side via the show-when-value-selected controller.
  class ConfigurationLinkComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpPrimer::FormHelpers
    include OpTurbo::Streamable

    renders_one :readonly_preview

    # +url+/+method+/+form_id+/+form_model+ let a host (the creation wizard) point the mode
    # form at its own endpoint, binding its fields under that model. +editor_form+ is an
    # ApplicationForm rendered inside the same form so the host's submit persists mode and
    # editor together; editors that self-persist via their own turbo endpoint come as the
    # block content instead. +link+ carries a rejected link so a failed aspect save can
    # re-render the picker inline with its errors.
    def initialize(type:, aspect:, link: nil, url: nil, method: nil, form_id: nil,
                   form_model: nil, with_submit: true, editor_form: nil, heading: nil)
      @aspect = aspect
      @link = link || type.configuration_links.find_or_initialize_by(aspect:)
      @url = url
      @method = method
      @form_id = form_id
      @form_model = form_model
      @with_submit = with_submit
      @editor_form = editor_form
      @heading = heading
      super(type)
    end

    def type = model

    def feature_active? = OpenProject::FeatureDecisions.subtypes_active?

    def linked? = @link.source_id.present?

    # The attempted/persisted source, or — when none yet (a fresh sub-type in the wizard,
    # any Independent aspect) — the parent a sub-type would normally reuse.
    def current_source = @link.source || type.parent

    # Aspect tab: a plain POST whose Independent/Linked toggle enables one of two `_method`
    # fields (patch/delete), so one model-bound form targets both verbs on the link's URL.
    # A host (wizard) supplies its own url/method and binds the fields to its own model.
    def form_options
      {
        url: @url || type_aspect_configuration_link_path(type, @aspect),
        method: @method || :post,
        linked: linked?,
        current_source_id: current_source&.id,
        source_options:,
        with_submit: @with_submit
      }.tap do |options|
        options[:html] = { id: @form_id } if @form_id
        options[:model] = @form_model || @link
      end
    end

    # A `_method` field per mode; show-when-value-selected disables the one whose mode
    # isn't selected, leaving only the active verb (PATCH link / DELETE independent).
    def method_field(verb, mode)
      helpers.tag.input(
        type: "hidden", name: "_method", value: verb,
        disabled: mode != current_mode,
        data: ConfigurationLinkForm.effect_data(mode)
      )
    end

    # The `_method` toggle only applies when we own the form; a host drives its own verb.
    def standalone? = @url.nil?

    def editor_form = @editor_form

    def heading = @heading

    def independent_data = WorkPackageTypes::ConfigurationLinkForm.effect_data("independent")

    def linked_data = WorkPackageTypes::ConfigurationLinkForm.effect_data("linked")

    def effective_source = type.effective_source_for(@aspect)

    # Aspect → the source type's own configuration tab. Only the two implemented aspects
    # resolve; anything else has no destination yet.
    def source_edit_path
      case @aspect
      when Type::ConfigurationLink::PATTERNS
        edit_type_subject_configuration_path(effective_source)
      when Type::ConfigurationLink::PDF_EXPORT
        edit_type_pdf_export_template_index_path(type_id: effective_source.id)
      end
    end

    private

    def current_mode = linked? ? "linked" : "independent"

    def wrapper_uniq_by = @aspect

    def source_options
      Type.global.where.not(id: type.id).order(:name)
    end
  end
end
