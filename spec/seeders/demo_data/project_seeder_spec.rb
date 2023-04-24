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

require 'spec_helper'

RSpec.describe DemoData::ProjectSeeder do
  subject(:project_seeder) { described_class.new(seed_data) }

  shared_let(:initial_seeding) do
    [
      # Color records needed by StatusSeeder and TypeSeeder
      BasicData::ColorSeeder,
      BasicData::ColorSchemeSeeder,

      # Status records needed by WorkPackageSeeder
      Standard::BasicData::StatusSeeder,

      # Type records needed by WorkPackageSeeder
      Standard::BasicData::TypeSeeder,

      # IssuePriority records needed by WorkPackageSeeder
      Standard::BasicData::PrioritySeeder,

      # admin user needed by ProjectSeeder
      AdminUserSeeder,

      # project admin role needed by ProjectSeeder
      BasicData::BuiltinRolesSeeder,
      BasicData::RoleSeeder
    ].each { |seeder| seeder.new.seed! }
  end

  let(:seed_data) { SeedData.new(project_data) }
  let(:project_data) { project_data_with_a_version }
  let(:project_data_with_a_version) do
    {
      'name' => 'Some project',
      'versions' => [
        {
          'name' => 'The product backlog',
          'reference' => :product_backlog,
          'sharing' => 'none',
          'status' => 'open'
        }
      ]
    }
  end

  it 'stores references to created versions in the seed data' do
    project_seeder.seed!
    created_version = Version.find_by(name: 'The product backlog')
    expect(seed_data.find_reference(:product_backlog)).to eq(created_version)
  end

  context 'for a version with a wiki' do
    before do
      project_data.update(
        'modules' => %w[work_package_tracking wiki],
        'wiki' => 'root wiki page content',
        'versions' => [
          {
            'name' => 'First sprint',
            'reference' => :first_sprint,
            'sharing' => 'none',
            'status' => 'open',
            'wiki' => {
              'title' => 'Sprint 1',
              'content' => 'Please see the [Task board](##sprint:first_sprint).'
            }
          }
        ]
      )
    end

    it 'can self-reference the version link in the wiki' do
      project_seeder.seed!
      created_version = Version.find_by!(name: 'First sprint')
      expect(created_version.wiki_page.content.text)
        .to eq("Please see the [Task board](/projects/some-project/sprints/#{created_version.id}/taskboard).")
    end
  end

  context 'with work packages linking to a version by its reference' do
    let(:project_data) do
      project_data_with_a_version.merge(
        'work_packages' => [
          {
            'subject' => 'Some work package',
            'status' => 'default_status_new',
            'type' => 'default_type_task',
            'version' => :product_backlog
          }
        ]
      )
    end

    it 'creates the link' do
      project_seeder.seed!
      version = Version.find_by(name: 'The product backlog')
      work_package = WorkPackage.find_by(subject: 'Some work package')
      expect(work_package.version).to eq(version)
    end
  end

  context 'with query linking to a version by its reference' do
    let(:project_data) do
      project_data_with_a_version.merge(
        'queries' => [
          {
            'name' => 'Product Backlog query',
            'status' => 'open',
            'version' => :product_backlog
          }
        ]
      )
    end

    it 'creates the link' do
      project_seeder.seed!
      version = Version.find_by(name: 'The product backlog')
      query = Query.find_by(name: 'Product Backlog query')
      expect(query.filters).to include(an_instance_of(Queries::WorkPackages::Filter::VersionFilter))
      version_filter = query.filters.find { _1.is_a?(Queries::WorkPackages::Filter::VersionFilter) }
      expect(version_filter.values).to eq([version.id.to_s])
    end
  end
end
