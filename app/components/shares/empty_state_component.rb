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

module Shares
  class EmptyStateComponent < ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
    include OpPrimer::ComponentHelpers

    def initialize(strategy:)
      super

      @strategy = strategy
      @entity = strategy.entity
    end

    private

    attr_reader :strategy, :entity

    def blankslate_config
      @blankslate_config ||= if params[:filters].blank?
                               unfiltered_blankslate_config
                             else
                               filtered_blankslate_config
                             end
    end

    def unfiltered_blankslate_config
      {
        icon: :people,
        heading_text: I18n.t("sharing.text_empty_state_header"),
        description_text: I18n.t("sharing.text_empty_state_description", entity: @entity.class.model_name.human)
      }
    end

    def filtered_blankslate_config
      {
        icon: :search,
        heading_text: I18n.t("sharing.text_empty_search_header"),
        description_text: I18n.t("sharing.text_empty_search_description")
      }
    end
  end
end
