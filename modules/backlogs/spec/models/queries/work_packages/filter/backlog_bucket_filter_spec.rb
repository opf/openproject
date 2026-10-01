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

require "spec_helper"

RSpec.describe Queries::WorkPackages::Filter::BacklogBucketFilter do
  let(:bucket) { build_stubbed(:backlog_bucket) }

  it_behaves_like "basic query filter" do
    let(:type) { :list_optional }
    let(:class_key) { :backlog_bucket_id }
    let(:values) { [bucket.id.to_s] }
    let(:model) { WorkPackage }

    let(:visible_scope) { instance_double(ActiveRecord::Relation) }
    let(:scoped_to_project) { instance_double(ActiveRecord::Relation) }
    let(:project_permissions) { [:view_sprints] }

    current_user { build_stubbed(:user) }

    before do
      allow(BacklogBucket)
        .to receive(:visible)
        .and_return(visible_scope)

      if project
        allow(visible_scope)
          .to receive(:where)
          .with(project:)
          .and_return(scoped_to_project)

        allow(scoped_to_project).to receive(:pluck).with(:id).and_return([bucket.id])
      else
        allow(visible_scope).to receive(:pluck).with(:id).and_return([bucket.id])
      end

      mock_permissions_for current_user do |mock|
        if project
          mock.allow_in_project(*project_permissions, project:)
        else
          mock.allow_in_project(*project_permissions, project: build_stubbed(:project))
        end
      end
    end

    describe "#allowed_values" do
      let(:bucket2) { build_stubbed(:backlog_bucket) }

      before do
        allow(scoped_to_project).to receive(:pluck).with(:id).and_return([bucket.id, bucket2.id])
      end

      it "returns id pairs for buckets visible in the project" do
        expect(instance.allowed_values).to contain_exactly(
          [bucket.id.to_s, bucket.id.to_s],
          [bucket2.id.to_s, bucket2.id.to_s]
        )
      end

      context "when outside a project" do
        let(:project) { nil }

        it "returns id pairs for all visible buckets" do
          expect(instance.allowed_values).to contain_exactly([bucket.id.to_s, bucket.id.to_s])
        end
      end
    end

    describe "#available?" do
      context "when in a project and the user has the permission" do
        it "is true" do
          expect(instance).to be_available
        end
      end

      context "when in a project and the user lacks the permission" do
        let(:project_permissions) { [] }

        it "is false" do
          expect(instance).not_to be_available
        end
      end

      context "when outside a project and the user has the permission" do
        let(:project) { nil }

        it "is true" do
          expect(instance).to be_available
        end
      end

      context "when outside a project and the user lacks the permission" do
        let(:project) { nil }
        let(:project_permissions) { [] }

        it "is false" do
          expect(instance).not_to be_available
        end
      end
    end

    describe "#ar_object_filter?" do
      it "is true" do
        expect(instance).to be_ar_object_filter
      end
    end

    describe "dependency representer" do
      it "maps to the backlog bucket dependency representer" do
        dependency = API::V3::Queries::Schemas::FilterDependencyRepresenterFactory
          .create(instance, Queries::Operators::Equals)

        expect(dependency).to be_a(API::V3::Queries::Schemas::BacklogBucketFilterDependencyRepresenter)
      end
    end

    describe "#value_objects" do
      let(:bucket1) { build_stubbed(:backlog_bucket) }
      let(:bucket2) { build_stubbed(:backlog_bucket) }

      before do
        allow(visible_scope)
          .to receive(:where)
          .with(project:)
          .and_return([bucket1, bucket2])

        instance.values = [bucket1.id.to_s]
      end

      it "returns an array of backlog buckets matching the set values" do
        expect(instance.value_objects).to contain_exactly(bucket1)
      end
    end
  end
end
