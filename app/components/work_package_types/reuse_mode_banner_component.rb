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
  # Banner above a type's configuration tab stating whether the aspect is
  # configured Independently or Linked to a source type, with the actions to
  # switch between the two modes.
  class ReuseModeBannerComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(type:, aspect:, routes: nil)
      @aspect = aspect
      @routes = routes || TypeRoutes.for(type)
      super(type)
    end

    def render? = OpenProject::FeatureDecisions.type_variants_active?

    private

    attr_reader :aspect

    def type = model

    def linked? = type.linked?(aspect)

    def source = type.source_for(aspect)

    def source_is_parent? = source.present? && source == type.parent

    def source_path = @routes.source_details(source)

    def copy_supported? = CopyConfiguration.supported?(aspect)

    def copy_dialog_path = @routes.configuration_copy_dialog(aspect)

    def link_dialog_path = @routes.configuration_link_dialog(aspect)

    def independent_dialog_path = @routes.configuration_independence_dialog(aspect)

    # Reuse mode is an administration concern; where its dialogs are out of reach the
    # banner reports the mode without offering to change it.
    def mode_switchable? = link_dialog_path.present?

    def linked_description
      return plain_linked_description if source_path.blank?

      helpers.link_translate(
        "types.edit.reuse_mode.linked.description",
        i18n_args: { source_name: source.composite_name, source_suffix: parent_suffix },
        links: { source_url: source_path },
        external: false
      )
    end

    # link_translate always renders an anchor, so the unlinked wording unwraps the
    # translation's own [name](source_url) markup and keeps the name.
    def plain_linked_description
      I18n.t("types.edit.reuse_mode.linked.description",
             source_name: source.composite_name,
             source_suffix: parent_suffix)
        .gsub(/\[([^\]]*)\]\(source_url\)/, '\1')
    end

    def parent_suffix
      source_is_parent? ? I18n.t("types.edit.reuse_mode.parent_suffix") : ""
    end
  end
end
