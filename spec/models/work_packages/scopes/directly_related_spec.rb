# --copyright
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
# ++

require "spec_helper"

RSpec.describe WorkPackages::Scopes::DirectlyRelated, ".directly_related scope" do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:origin) { create(:work_package) }
  shared_let(:related_work_package_to) { create(:work_package) }
  shared_let(:transitively_related_work_package_to) { create(:work_package) }
  shared_let(:related_work_package_from) { create(:work_package) }
  shared_let(:transitively_related_work_package_from) { create(:work_package) }
  shared_let(:unrelated_work_package) { create(:work_package) }

  let(:relation_from) do
    create(:relation,
           relation_type:,
           from: origin,
           to: related_work_package_from)
  end
  let(:relation_to) do
    create(:relation,
           relation_type:,
           to: origin,
           from: related_work_package_to)
  end
  let(:transitive_relation_from) do
    create(:relation,
           relation_type:,
           from: related_work_package_from,
           to: transitively_related_work_package_from)
  end
  let(:transitive_relation_to) do
    create(:relation,
           relation_type:,
           to: related_work_package_to,
           from: transitively_related_work_package_to)
  end
  let(:ignored_relations) { nil }

  let!(:existing_relations) { [relation_to, transitive_relation_to, relation_from, transitive_relation_from] }

  subject(:directly_related) { WorkPackage.directly_related(origin, ignored_relation: ignored_relations) }

  it "is an AR scope" do
    expect(directly_related)
      .to be_a ActiveRecord::Relation
  end

  Relation::TYPES.each_key do |current_type|
    let(:relation_type) { current_type }

    context "with existing relations of type '#{current_type}'" do
      it "contains the directly related work packages in both directions" do
        expect(directly_related)
          .to contain_exactly(related_work_package_to, related_work_package_from)
      end
    end

    context "with existing relations of type '#{current_type}' and ignoring one relation" do
      let(:ignored_relations) { relation_to }

      it "contains the directly related work packages for which the relation isn`t ignored" do
        expect(directly_related)
          .to contain_exactly(related_work_package_from)
      end
    end
  end
end
