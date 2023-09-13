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

    def call
      render(BorderBoxComponent.new(padding: :default, scheme: :default)) do |component|
        header_slot(component)
        rows_slot(component)
      end
    end

    def header_slot(component)
      component.with_header do |header|
        header.with_title(tag: :h2) do
          header_title
        end
      end
    end

    def rows_slot(component)
      storages.map do |storage|
        component.with_row(scheme: :default, id: storage_row_css_id(storage)) do
          storage_row(storage)
        end
      end
    end

    private

    def storage_row(storage)
      storage_name_div(storage) +
        div_tag(storage_creator(storage)) +
        div_tag(storage.provider_type) +
        div_tag(storage.host)
    end

    def storage_name_div(storage)
      div_tag(
        storage_name(storage) +
          span_tag("Created on #{storage.created_at.to_fs(:long)}")
      )
    end

    def storage_row_css_id(storage)
      helpers.dom_id storage
    end

    def header_title
      helpers.pluralize(storages.size, I18n.t("storages.label_storage"))
    end

    def storage_name(storage)
      if storage.configured?
        span_tag(storage.name)
      else
        render(Primer::Beta::Octicon.new(:'alert-fill', size: :small, color: :severe)) +
          span_tag(storage.name, classes: 'pl-2')
      end
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

  class BorderBoxComponent < Primer::Beta::BorderBox
    def before_render
      super

      # Remove the _base.sass margin-left from <ul> tag
      @list_arguments[:classes] = "ml-0"
    end
  end
end
