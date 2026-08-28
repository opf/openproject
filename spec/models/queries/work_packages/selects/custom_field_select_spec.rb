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
require_relative "shared_query_select_specs"

RSpec.describe Queries::WorkPackages::Selects::CustomFieldSelect do
  let(:project) { build_stubbed(:project) }
  let(:custom_field) { build_stubbed(:string_wp_custom_field) }
  let(:instance) { described_class.new(custom_field) }

  it_behaves_like "query column", sortable_by_default: true

  describe "instances" do
    shared_let(:type) { create(:type) }
    shared_let(:visible_project) { create(:project, public: false, types: [type]) }
    shared_let(:text_custom_field) { create(:text_wp_custom_field, types: [type]) }
    shared_let(:list_custom_field) { create(:list_wp_custom_field, types: [type]) }
    shared_let(:member) { create(:user, member_with_permissions: { visible_project => [] }) }

    current_user { member }

    context "within a project whose types configure the fields" do
      it "contains only non text cf columns" do
        expect(described_class.instances(visible_project).map(&:custom_field))
          .to contain_exactly(list_custom_field)
      end
    end

    context "with a user who cannot see the project" do
      current_user { create(:user) }

      it "is empty" do
        expect(described_class.instances(visible_project)).to be_empty
      end
    end

    context "when global" do
      it "contains only non text cf columns" do
        expect(described_class.instances.map(&:custom_field))
          .to contain_exactly(list_custom_field)
      end

      context "with a user who cannot see any project" do
        current_user { create(:user) }

        it "is empty" do
          expect(described_class.instances).to be_empty
        end
      end
    end
  end
end
