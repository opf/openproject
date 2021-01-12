#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

# For the sake of this coding exercise, a company is a very simple structure that only has
# * an id
# * a name
# * a single owner
#
# The owner is a User object that already exists in OpenProject. Consequently, there are also
# representers already available for rendering a user (API::V3::Users::UserRepresenter).
#
# The company can also belong to one or many different companies. This is expressed by a parent
# company having a share in a child company. For the sake of simplicity a share is binary. A company
# either has a share in another company or not. There is no representation of a ratio on how much
# of the child company is owned by a parent company. However, a share can be inactive (because this is
# an example).
#
# The resource should include:
# * The id
# * The name
# * The actual users owning the company
#
# The first two are straight forward. The later however requires some explanation. For the sake of this
# example, the set of owning users are those users, that are owners of companies, which are parents
# (or any ancestor) to the company being represented. Those owners than overrule any owner directly
# linked to the represented company. This overruling takes place on every level of ancestry.
#
# E.g. In a set of companies
#
# grandparent - (owner A)
# parent - (owner B)
# child - (owner C)
#
# the owning user of child is A.
#
# To complicate matters, that overruling only takes place if the share is active. So in the example above,
# with the share between parent and grandparent not being active, the owning user of child would be B.
#
# If a company has no parent or only has parents on inactive shares, the owning user is the user of the company.
# Referring to the example again, if the share between child and parent were to be inactive (or to not exist
# at all), the owning user of child would be C.
#
# Since a company can have multiple parents, there can also be multiple owning users
#
# E.g. in a set of companies
#
#                                  grandgrandparent 1 (parent to grandparent 2) - (owner A)
# grandparent 1 - (owner B)        grandparent 2 - (owner C)
#                  parent - (owner D)
#                  child - (owner E)
#
# assuming that every share is active, the owning users of child would be A and B.

describe 'API v3 companies resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  subject(:response) { last_response }

  let(:admin) do
    FactoryBot.create(:admin)
  end
  let(:owner) do
    FactoryBot.create(:user, firstname: 'The', lastname: 'owner')
  end
  let(:company) do
    FactoryBot.create(:company, owner: owner)
  end

  current_user do
    FactoryBot.create(:user)
  end

  describe 'GET /api/v3/companies/:id' do
    let(:path) { api_v3_paths.company(company.id) }

    before do
      get path
    end

    it 'returns 200 OK' do
      expect(subject.status)
        .to be(200)
    end

    it 'returns the company' do
      expect(subject.body)
        .to be_json_eql('Company'.to_json)
        .at_path('_type')

      expect(subject.body)
        .to be_json_eql(company.id.to_json)
        .at_path('id')

      expect(subject.body)
        .to be_json_eql(company.name.to_json)
        .at_path('name')
    end

    it 'references the owning users' do
      # References the owner of the company
      expect(subject.body)
        .to be_json_eql(api_v3_paths.user(owner.id).to_json)
              .at_path('_links/owningUsers/0/href')

      expect(subject.body)
        .to be_json_eql(owner.name.to_json)
              .at_path('_embedded/owningUsers/0/name')
    end

    # rubocop:disable Naming/VariableNumber
    # rubocop:disable RSpec/MultipleMemoizedHelpers
    context 'with a web of companies' do
      let(:parent_company1_2_1) do
        FactoryBot.create(:company, owner: owner_pc1_2_1)
      end
      let(:parent_company1_2_2) do
        FactoryBot.create(:company, owner: owner_pc1_2_2)
      end

      let(:parent_company1_1) do
        FactoryBot.create(:company, owner: owner_pc1_1)
      end
      let(:parent_company1_2) do
        FactoryBot.create(:company, owner: owner_pc1_2).tap do |company|
          FactoryBot.create(:share, active: false, parent: parent_company1_2_1, child: company)
          FactoryBot.create(:share, active: true, parent: parent_company1_2_2, child: company)
        end
      end

      let(:parent_company1) do
        FactoryBot.create(:company, owner: owner_pc1).tap do |company|
          FactoryBot.create(:share, active: false, parent: parent_company1_1, child: company)
          FactoryBot.create(:share, active: true, parent: parent_company1_2, child: company)
        end
      end

      let(:parent_company2_1_1) do
        FactoryBot.create(:company, owner: owner_pc2_1_1)
      end

      let(:parent_company2_3_1) do
        FactoryBot.create(:company, owner: owner_pc2_3_1)
      end

      let(:parent_company2_3_2) do
        FactoryBot.create(:company, owner: owner_pc2_3_2)
      end

      let(:parent_company2_1) do
        FactoryBot.create(:company, owner: owner_pc2_1).tap do |company|
          FactoryBot.create(:share, active: true, parent: parent_company2_1_1, child: company)
        end
      end

      let(:parent_company2_2) do
        FactoryBot.create(:company, owner: owner_pc2_2)
      end

      let(:parent_company2_3) do
        FactoryBot.create(:company, owner: owner_pc2_3).tap do |company|
          FactoryBot.create(:share, active: false, parent: parent_company2_3_1, child: company)
          FactoryBot.create(:share, active: false, parent: parent_company2_3_2, child: company)
        end
      end

      let(:parent_company2) do
        FactoryBot.create(:company, owner: owner_pc2).tap do |company|
          FactoryBot.create(:share, active: false, parent: parent_company2_1, child: company)
          FactoryBot.create(:share, active: true, parent: parent_company2_2, child: company)
          FactoryBot.create(:share, active: true, parent: parent_company2_3, child: company)
        end
      end

      let(:company) do
        FactoryBot.create(:company, owner: owner).tap do |company|
          FactoryBot.create(:share, active: true, parent: parent_company1, child: company)
          FactoryBot.create(:share, active: true, parent: parent_company2, child: company)
        end
      end

      let(:owner_pc2) { FactoryBot.create(:user) }
      let(:owner_pc2_1) { FactoryBot.create(:user) }
      let(:owner_pc2_2) { FactoryBot.create(:user) }
      let(:owner_pc2_3) { FactoryBot.create(:user) }
      let(:owner_pc2_3_1) { FactoryBot.create(:user) }
      let(:owner_pc2_3_2) { FactoryBot.create(:user) }
      let(:owner_pc2_1_1) { FactoryBot.create(:user) }
      let(:owner_pc1) { FactoryBot.create(:user) }
      let(:owner_pc1_1) { FactoryBot.create(:user) }
      let(:owner_pc1_2) { FactoryBot.create(:user) }
      let(:owner_pc1_2_1) { FactoryBot.create(:user) }
      let(:owner_pc1_2_2) { FactoryBot.create(:user) }

      let(:chairman) do
        FactoryBot.create(:user, firstname: 'Big', lastname: 'Boss')
      end

      let(:expected_owners) do
        [owner_pc1_2_2,
         owner_pc2_2,
         owner_pc2_3]
      end

      it 'references the owning_users (only users that are not owners of a company owned actively by another company)' do
        # References the owner of the holding
        expect(subject.body)
          .to have_json_path('_links/owningUsers')

        expect(JSON.parse(subject.body).dig('_links', 'owningUsers').map { |owner| owner['href'] })
          .to match_array(expected_owners.map { |o| api_v3_paths.user(o.id) })

        expect(subject.body)
          .to have_json_path('_embedded/owningUsers')

        expect(JSON.parse(subject.body).dig('_embedded', 'owningUsers').map { |owner| owner['id'] })
          .to match_array(expected_owners.map(&:id))
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
    # rubocop:enable Naming/VariableNumber

    context 'when querying a non existing company' do
      let(:path) { api_v3_paths.company(company.id + 1) }

      it_behaves_like 'not found'
    end

    context 'without begin logged in', with_settings: { login_required?: true } do
      current_user { nil }

      it_behaves_like 'unauthenticated access'
    end
  end
end
