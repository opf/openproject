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
class CompositeSeeder < Seeder
  def seed_data!
    ActiveRecord::Base.transaction do
      seed_with(data_seeders)

      if discovered_seeders.any?
        print_status "Loading discovered seeders: #{discovered_seeders.map { seeder_name(_1) }.join(', ')}"
        seed_with(discovered_seeders)
      end
    end
  end

  def seed_with(seeders)
    seeders.each do |seeder|
      print_status " ↳ #{seeder_name(seeder)}"
      seeder.seed!
    end
  end

  def data_seeders
    instantiate(data_seeder_classes)
  end

  def data_seeder_classes
    raise NotImplementedError, "has to be implemented by subclasses"
  end

  def discovered_seeders
    instantiate(discovered_seeder_classes)
  end

  ##
  # Discovered seeders defined outside of the core (i.e. in plugins).
  #
  # Seeders defined in the core have a simple namespace, e.g. 'BasicData'
  # or 'DemoData'. Plugins must define their seeders in their own namespace,
  # e.g. 'BasicData::Documents' in order to avoid name conflicts.
  def discovered_seeder_classes
    Seeder
      .descendants
      .reject { |cl| cl.to_s.deconstantize == namespace }
      .select { |cl| include_discovered_class? cl }
  end

  def namespace
    raise NotImplementedError, "has to be implemented by subclasses"
  end

  ##
  # Accepts plugin seeders, e.g. 'BasicData::Documents'.
  def include_discovered_class?(discovered_class)
    discovered_class.name =~ /^#{namespace}::/
  end

  def seeder_name(seeder)
    seeder.class.name.split("::").without(namespace).join("::")
  end

  def instantiate(seeder_classes)
    seeder_classes.map { |seeder_class| seeder_class.new(seed_data) }
  end
end
