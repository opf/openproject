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

class FlipBcfViewpointClippingDirectionSelectively < ActiveRecord::Migration[6.1]
  def up
    flip_op_clipping_planes
  end

  def down
    flip_op_clipping_planes
  end

  private

  def flip_op_clipping_planes
    viewpoints = select_viewpoints_created_in_op
    viewpoints.each do |viewpoint|
      new_json_viewpoint = flip_clipping_planes(viewpoint.json_viewpoint)
      viewpoint.update_column(:json_viewpoint, new_json_viewpoint)
    end
  end

  def select_viewpoints_created_in_op
    join_condition = %{
      bcf_viewpoints.json_viewpoint->>'clipping_planes' IS NOT NULL
      AND
      (
        bcf_issues.markup IS NULL
        OR
        XPATH_EXISTS('/comment()[contains(., ''Created by OpenProject'')]', bcf_issues.markup)
      )
    }
    ::Bim::Bcf::Viewpoint.joins(:issue).where(join_condition)
  end

  def flip_clipping_planes(viewpoint)
    viewpoint_dup = viewpoint.deep_dup
    viewpoint_dup["clipping_planes"].each do |plane|
      plane["direction"]["x"] *= -1
      plane["direction"]["y"] *= -1
      plane["direction"]["z"] *= -1
    end

    viewpoint_dup
  end
end
