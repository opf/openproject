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

require 'spec_helper'
require_relative './root_seeder_shared_examples'

describe RootSeeder,
         'standard edition',
         with_config: { edition: 'standard' } do
  include RootSeederTestHelpers

  shared_examples 'creates standard demo data' do
    it 'creates the system user' do
      expect(SystemUser.where(admin: true).count).to eq 1
    end

    it 'creates an admin user' do
      expect(User.not_builtin.where(admin: true).count).to eq 1
    end

    it 'creates the demo data' do
      expect(Project.count).to eq 2
      expect(WorkPackage.count).to eq 36
      expect(Wiki.count).to eq 2
      expect(Query.having_views.count).to eq 8
      expect(View.where(type: 'work_packages_table').count).to eq 7
      expect(View.where(type: 'team_planner').count).to eq 1
      expect(Query.count).to eq 26
      expect(Role.where(type: 'Role').count).to eq 5
      expect(GlobalRole.count).to eq 1
      expect(Grids::Overview.count).to eq 2
      expect(Version.count).to eq 4
      expect(VersionSetting.count).to eq 4
      expect(Boards::Grid.count).to eq 5
      expect(Boards::Grid.count { |grid| grid.options.has_key?(:filters) }).to eq 1
    end

    it 'links work packages to their version' do
      count_by_version = WorkPackage.joins(:version).group('versions.name').count
      count_by_version.transform_keys! { _1.gsub(/^tr: /, '') } # revert simulated translation if any
      expect(count_by_version).to eq(
        'Bug Backlog' => 1,
        'Sprint 1' => 8,
        'Product Backlog' => 7
      )
    end

    it 'creates different types of queries' do
      count_by_type = View.group(:type).count
      expect(count_by_type).to eq(
        "work_packages_table" => 7,
        "team_planner" => 1
      )
    end
  end

  describe 'demo data' do
    before_all do
      with_edition('standard') do
        described_class.new.seed_data!
      end
    end

    include_examples 'creates standard demo data'

    include_examples 'no email deliveries'

    context 'when run a second time' do
      before_all do
        described_class.new.seed_data!
      end

      it 'does not create additional data' do
        expect(Project.count).to eq 2
        expect(WorkPackage.count).to eq 36
        expect(Wiki.count).to eq 2
        expect(Query.having_views.count).to eq 8
        expect(View.where(type: 'work_packages_table').count).to eq 7
        expect(View.where(type: 'team_planner').count).to eq 1
        expect(Query.count).to eq 26
        expect(Role.where(type: 'Role').count).to eq 5
        expect(GlobalRole.count).to eq 1
        expect(Grids::Overview.count).to eq 2
        expect(Version.count).to eq 4
        expect(VersionSetting.count).to eq 4
        expect(Boards::Grid.count).to eq 5
      end
    end
  end

  describe 'demo data mock-translated in another language' do
    before_all do
      with_edition('standard') do
        # simulate a translation by changing the returned string on `I18n#t` calls
        allow(I18n).to receive(:t).and_wrap_original do |m, *args, **kw|
          original_translation = m.call(*args, **kw)
          "tr: #{original_translation}"
        end
        described_class.new.seed_data!
      end
    end

    include_examples 'creates standard demo data'

    it 'has all Query.name translated' do
      expect(Query.pluck(:name)).to all(start_with('tr: '))
    end
  end

  describe 'demo data with a non-English language' do
    before_all do
      with_edition('standard') do
        stub_language('de')
        described_class.new.seed_data!
      end
    end

    before do
      stub_language('de')
    end

    include_examples 'creates standard demo data'
  end

  describe 'demo data with development data' do
    before_all do
      described_class.new(seed_development_data: true).seed_data!
    end

    it 'creates 1 additional admin user with German locale' do
      admins = User.not_builtin.where(admin: true)
      expect(admins.count).to eq 2
      expect(admins.pluck(:language)).to match_array(%w[en de])
    end

    it 'creates 4 additional projects for development' do
      expect(Project.count).to eq 6
    end

    include_examples 'no email deliveries'
  end
end
