# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
module Storages::Admin
  class StorageListComponent < ApplicationComponent
    alias_method :storages, :model

    private

    def storage_row_css_id(storage)
      helpers.dom_id storage
    end

    def formatted_storage_name(storage)
      if storage.configured?
        span_tag(storage.name)
      else
        render(Primer::Beta::Octicon.new(:'alert-fill', size: :small, color: :severe)) +
          span_tag(storage.name, classes: 'pl-2')
      end
    end

    def formatted_datetime(storage)
      span_tag(" #{I18n.t('activity.item.created_on', datetime: helpers.format_time(storage.created_at.to_fs(:long)))}")
    end

    def storage_creator(storage)
      # TODO: Replace with `Users::AvatarComponent` once https://github.com/opf/openproject/pull/13527 is merged
      helpers.avatar(storage.creator, size: :mini) +
        storage.creator.name
    end

    def span_tag(item, **)
      base_component_tag(item, tag: :span, **)
    end

    def div_tag(item, **)
      base_component_tag(item, tag: :div, **)
    end

    def base_component_tag(item, tag:, **)
      render(Primer::BaseComponent.new(tag:, **)) { item }
    end
  end
end
