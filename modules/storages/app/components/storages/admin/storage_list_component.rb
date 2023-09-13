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
  class StorageListComponent < Primer::Beta::BorderBox
    attr_reader :storages

    def initialize(storages:, padding: :default, scheme: :default, **system_arguments)
      @storages = storages
      super(padding:, scheme:, **system_arguments)
    end

    def header
      with_header do |header_|
        header_.with_title(tag: :h2) do
          header_title
        end
      end
    end

    def header_title
      helpers.pluralize(storages.size, I18n.t("storages.label_storage"))
    end

    def rows
      @storages.map do |storage|
        with_row(scheme: :default, id: storage_row_css_id(storage)) do
          storage_row(storage)
        end
      end
    end

    def storage_row(storage)
      div_tag(
        storage_name(storage) + span_tag("Created on #{storage.created_at.to_fs(:long)}")
      ) +
        div_tag(storage_creator(storage)) +
        div_tag(storage.provider_type) +
        div_tag(storage.host)
    end

    def storage_row_css_id(storage)
      helpers.dom_id storage
    end

    private

    def before_render
      super

      # Remove the _base.sass margin-left from <ul> tag
      @list_arguments[:classes] = "ml-0"
    end

    def storage_name(storage)
      storage_name_span = span_tag(storage.name)

      if storage.configured?
        storage_name_span
      else
        render(Primer::Beta::Octicon.new(:'alert-fill', size: :small, color: :severe)) +
          storage_name_span
      end
    end

    def storage_creator(storage)
      icon = helpers.avatar storage.creator, size: :mini
      icon + storage.creator.name
    end

    def span_tag(item, options = {})
      content_tag(:span, item, options)
    end

    def div_tag(item)
      render(Primer::BaseComponent.new(tag: :div)) { item }
    end
  end
end
