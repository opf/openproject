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

require Rails.root.join("db/migrate/migration_utils/squashed_migration").to_s
Dir[File.join(__dir__, "tables/*.rb")].each { |file| require file }

class AggregatedBimMigrations < SquashedMigration
  squashed_migrations *%w[
    20181214103300_add_bcf_plugin
    20190719123448_add_viewpoint_to_bcf_comment
    20190823090211_remove_project_id_from_bcf_issue
    20191029155327_add_ifc_models_plugin
    20191114090353_add_is_default_to_ifc_models
    20191119144123_add_issue_columns
    20191121140202_migrate_xml_viewpoint_to_json
    20200123163818_add_on_delete_nullify_to_bcf_comment_foreign_key_to_viewpoint
    20200310092237_add_timestamps_to_bcf
    20200610083854_add_uniqueness_contrain_to_bcf_topic_on_uuid
    20201105154216_seed_custom_style_with_bim_theme
    20210521080035_update_xkt_to_version8
    20210713081724_flip_bcf_viewpoint_clipping_direction_selectively
    20210910092414_add_bcf_comment_hierarchy
    20211011204301_add_column_conversion_status_to_ifc_model
    20211022143726_remove_snapshot_data
  ].freeze

  tables Tables::BcfIssues,
         Tables::BcfViewpoints,
         Tables::BcfComments,
         Tables::IfcModels
end
