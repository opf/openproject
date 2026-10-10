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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Exports::PDF::ZendisArtefact::Styles
  class PDFStyles < Exports::PDF::Artefact::Styles::PDFStyles
    def initialize(styles_asset_path = __dir__)
      artefact_path = File.expand_path("../artefact", __dir__)
      super(artefact_path)
      overrides = YAML.load_file(File.join(styles_asset_path, "standard.yml"))
      schema = JSON.load_file(File.join(artefact_path, "schema.json"))
      schema.deep_merge!(JSON.load_file(File.join(styles_asset_path, "schema.json")))
      validate_schema!(overrides, schema)
      @styles.deep_merge!(overrides.deep_symbolize_keys)
    end

    def layout
      @styles[:layout]
    end

    def section_title_cell
      resolve_table_cell(@styles.dig(:section, :title))
    end
  end
end
