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

RSpec.describe API::V3::Queries::Schemas::ProjectFilterDependencyRepresenter do
  include API::V3::Utilities::PathHelper

  let(:filter) { Queries::WorkPackages::Filter::ProjectFilter.create! }
  let(:form_embedded) { false }

  let(:instance) do
    described_class.new(filter,
                        operator,
                        form_embedded:)
  end

  subject(:generated) { instance.to_json }

  context "with generation" do
    context "for properties" do
      let(:path) { "values" }
      let(:type) { "[]Project" }
      let(:filters) do
        "?filters=%5B%7B%22active%22%3A%7B%22operator%22%3A%22%3D%22%2C%22values%22%3A%5B%22t%22%5D%7D%7D%5D&pageSize=-1"
      end
      let(:href) { api_v3_paths.projects + filters }

      context "for operator 'Queries::Operators::Equals'" do
        let(:operator) { Queries::Operators::Equals }

        it_behaves_like "filter dependency with allowed link"
      end

      context "for operator 'Queries::Operators::NotEquals'" do
        let(:operator) { Queries::Operators::NotEquals }

        it_behaves_like "filter dependency with allowed link"
      end

      context "for operator 'Queries::Operators::All'" do
        let(:operator) { Queries::Operators::All }

        it_behaves_like "filter dependency empty"
      end

      context "for operator 'Queries::Operators::None'" do
        let(:operator) { Queries::Operators::None }

        it_behaves_like "filter dependency empty"
      end
    end

    describe "caching" do
      let(:operator) { Queries::Operators::Equals }

      it_behaves_like "filter dependency caching"
    end
  end
end
