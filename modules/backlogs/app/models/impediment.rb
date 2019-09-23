#-- copyright
# OpenProject Backlogs Plugin
#
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Impediment < Task
  extend OpenProject::Backlogs::Mixins::PreventIssueSti

  after_save :update_blocks_list

  validate :validate_blocks_list

  def self.default_scope
    roots
      .where(type_id: type)
  end

  def blocks_ids=(ids)
    @blocks_ids_list = [ids] if ids.is_a?(Integer)
    @blocks_ids_list = ids.split(/\D+/).map(&:to_i) if ids.is_a?(String)
    @blocks_ids_list = ids.map(&:to_i) if ids.is_a?(Array)
  end

  def blocks_ids
    @blocks_ids_list ||= block_ids
  end

  private

  def update_blocks_list
    self.block_ids = blocks_ids
  end

  def validate_blocks_list
    if blocks_ids.size == 0
      errors.add :blocks_ids, :must_block_at_least_one_work_package
    else
      other_version_ids = WorkPackage.where(id: blocks_ids).pluck(:fixed_version_id).uniq
      errors.add :blocks_ids, :can_only_contain_work_packages_of_current_sprint if other_version_ids.size != 1 || other_version_ids[0] != fixed_version_id
    end
  end
end
