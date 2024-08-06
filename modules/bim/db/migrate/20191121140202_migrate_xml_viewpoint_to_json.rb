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

class MigrateXmlViewpointToJson < ActiveRecord::Migration[6.0]
  def up
    # Add JSON viewpoint
    change_table :bcf_viewpoints do |t|
      t.jsonb :json_viewpoint
    end

    # Convert viewpoints
    ::Bim::Bcf::Viewpoint.reset_column_information
    ::Bim::Bcf::Viewpoint.find_each do |resource|
      mapper = ::OpenProject::Bim::BcfJson::ViewpointReader
        .new(resource.uuid, resource.viewpoint)

      resource.update_column(:json_viewpoint, mapper.result)

      Rails.logger.debug { "Converted viewpoint (##{resource.id}) #{resource.uuid} to JSON." }
    rescue StandardError => e
      warn "Failed to convert viewpoint #{viewpoint.uuid}: #{e} #{e.message}"
    end

    # Remove the old XML viewpoint
    change_table :bcf_viewpoints do |t|
      t.remove :viewpoint
    end
  end

  def down
    raise "Cannot be reverted yet!"
  end
end
