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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

RSpec.shared_context "with basic seed data" do |edition: "standard"|
  def add_needed_seeders_for(seeder_class, needed_acc)
    seeder_class.needs.each do |needed_seeder_class|
      next if needed_acc.include?(needed_seeder_class)

      add_needed_seeders_for(needed_seeder_class, needed_acc)
      next if needed_acc.include?(needed_seeder_class)

      needed_acc << needed_seeder_class
    end
  end

  shared_let(:needed_seeders) do
    needed = []
    add_needed_seeders_for(described_class, needed)
    needed
  end
  shared_let(:needed_seeders_keys) do
    # warning: there is one limitation: RoleSeeder will only pick 'roles' key,
    # and not 'modules_permissions' key.
    needed_seeders.map { _1.try(:seed_data_model_key) }.compact
  end
  shared_let(:basic_seed_data) do
    Source::SeedDataLoader.get_data(edition:).only(*needed_seeders_keys)
  end
  shared_let(:basic_seeding) do
    needed_seeders.each { |seeder| seeder.new(basic_seed_data).seed! }
  end
end
