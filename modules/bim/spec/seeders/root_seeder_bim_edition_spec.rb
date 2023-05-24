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
require_relative '../../../../spec/seeders/root_seeder_shared_examples'

RSpec::Matchers.define_negated_matcher :not_start_with, :start_with

describe RootSeeder,
         'BIM edition',
         with_config: { edition: 'bim' } do
  include RootSeederTestHelpers

  shared_examples 'creates BIM demo data' do
    it 'creates an admin user' do
      expect(User.not_builtin.where(admin: true).count).to eq 1
    end

    it 'creates the BIM demo data' do
      expect(Project.count).to eq 4
      expect(WorkPackage.count).to eq 76
      expect(Wiki.count).to eq 3
      expect(Query.count).to eq 29
      expect(Group.count).to eq 8
      expect(Type.count).to eq 7
      expect(Status.count).to eq 4
      expect(IssuePriority.count).to eq 4
      expect(Bim::IfcModels::IfcModel.count).to eq 3
      expect(Grids::Overview.count).to eq 4
      expect(Boards::Grid.count).to eq 2
    end

    it 'creates follows and parent-child relations' do
      expect(Relation.follows.count).to eq 35
      expect(WorkPackage.where.not(parent: nil).count).to eq 55
    end

    it 'assigns work packages to groups' do
      count_by_assignee =
        WorkPackage
          .joins(:assigned_to)
          .group("array_to_string(ARRAY[type || ':', firstname, lastname], ' ')")
          .count
          .transform_keys! { |key| key.squish.gsub('tr: ', '') }
      expect(count_by_assignee).to eq(
        "Group: Architects" => 1,
        "Group: BIM Coordinators" => 11,
        "Group: BIM Managers" => 2,
        "Group: BIM Modellers" => 21,
        "Group: Lead BIM Coordinators" => 8,
        "Group: Planners" => 21,
        "User: OpenProject Admin" => 12
      )
    end
  end

  describe 'demo data' do
    before_all do
      with_edition('bim') do
        described_class.new.seed_data!
      end
    end

    include_examples 'creates BIM demo data'

    include_examples 'no email deliveries'
  end

  describe 'demo data mock-translated in another language' do
    before_all do
      with_edition('bim') do
        # simulate a translation by changing the returned string on `I18n#t` calls
        allow(I18n).to receive(:t).and_wrap_original do |m, *args, **kw|
          original_translation = m.call(*args, **kw)
          "tr: #{original_translation}"
        end

        described_class.new.seed_data!
      end
    end

    include_examples 'creates BIM demo data'

    it 'has all Query.name translated' do
      expect(Query.pluck(:name)).to all(start_with('tr: '))
    end

    context 'for work packages NOT related to a BCF issue' do
      let(:work_packages) { WorkPackage.left_joins(:bcf_issue).where('bcf_issues.id': nil) }

      %w[subject description].each do |field|
        it "have their #{field} field translated" do
          expect(work_packages.pluck(:subject)).to all(start_with('tr: '))
        end
      end
    end

    # TODO: the data coming from BCF files should be translated too
    # This is recorded in the implementation work package 47998
    context 'for work packages related to a BCF issue' do
      let(:work_packages) { WorkPackage.joins(:bcf_issue).where.not('bcf_issues.id': nil) }

      %w[subject description].each do |field|
        it "have NOT their #{field} field translated" do
          expect(work_packages.pluck(:subject)).to all(not_start_with('tr: '))
        end
      end
    end
  end

  describe 'demo data with a non-English language' do
    before_all do
      with_edition('bim') do
        stub_language('de')
        described_class.new.seed_data!
      end
    end

    before do
      stub_language('de')
    end

    include_examples 'creates BIM demo data'
  end
end
