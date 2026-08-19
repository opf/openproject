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

RSpec.describe Workflows::CopiesController do
  let!(:source_type) do
    build_stubbed(:type) do |stub|
      allow(Type)
        .to receive(:find)
              .with(stub.id.to_s)
              .and_return(stub)
    end
  end

  let!(:other_types) do
    build_stubbed_list(:type, 2).tap do |stubs|
      where_double = instance_double(ActiveRecord::QueryMethods::WhereChain)
      not_double = instance_double(ActiveRecord::Relation)

      allow(Type).to receive(:where).and_return(where_double)
      allow(where_double).to receive(:not).and_return(not_double)
      allow(not_double).to receive(:order).and_return(stubs)
    end
  end

  let!(:eligible_roles) do
    instance_double(ActiveRecord::Relation, to_a: all_roles).tap do |relation|
      allow(Role)
        .to receive(:where)
              .with(type: ProjectRole.name)
              .and_return(relation)
    end
  end

  let!(:all_roles) do
    build_stubbed_list(:project_role, 2)
  end

  let!(:source_role) { nil }

  before do
    allow(eligible_roles).to receive(:find_by).and_return(source_role)
  end

  current_user { build_stubbed(:admin) }

  describe "#new" do
    let(:params) do
      { workflow_type_id: source_type.id.to_s, source_role_id: source_role&.id }
    end

    before do
      get :new, params:, format: :turbo_stream
    end

    it "is a success" do
      expect(response)
        .to have_http_status(:ok)
    end

    it "renders the correct template" do
      expect(response)
        .to render_template :new
    end

    it "assigns the source type" do
      expect(assigns[:source_type])
        .to eq source_type
    end

    it "assigns the other types" do
      expect(assigns[:other_types])
      .to match_array(other_types)
    end

    it "does not assign any source role" do
      expect(assigns[:source_role])
        .to be_nil
    end

    it "assigns the eligible roles" do
      expect(assigns[:all_roles])
        .to match_array(all_roles)
    end

    describe "when the source role is specified" do
      let!(:source_role) { all_roles.sample }

      it "assigns the source role" do
        expect(assigns[:source_role])
          .to eq source_role
      end
    end
  end
end
