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

describe  'API v3 Relation resource', type: :request, content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:user) { FactoryBot.create :admin }
  let(:current_user) { user }

  let!(:from) { FactoryBot.create :work_package }
  let!(:to) { FactoryBot.create :work_package }

  let(:type) { "follows" }
  let(:description) { "This first" }
  let(:delay) { 3 }

  let(:params) do
    {
      _links: {
        from: {
          href: "/api/v3/work_packages/#{from.id}"
        },
        to: {
          href: "/api/v3/work_packages/#{to.id}"
        }
      },
      type: type,
      description: description,
      delay: delay
    }
  end
  let(:relation) do
    FactoryBot.create :relation,
                      from: from,
                      to: to,
                      relation_type: type,
                      description: description,
                      delay: delay
  end

  before do
    login_as current_user
  end

  describe "creating a relation" do
    shared_examples_for 'creates the relation' do
      it 'creates the relation correctly' do
        rel = ::API::V3::Relations::RelationPayloadRepresenter.new(Relation.new, current_user: user).from_json last_response.body

        expect(rel.from).to eq from
        expect(rel.to).to eq to
        expect(rel.relation_type).to eq type
        expect(rel.description).to eq description
        expect(rel.delay).to eq delay
      end
    end

    let(:setup) {}
    before do
      setup

      header "Content-Type", "application/json"
      post "/api/v3/work_packages/#{from.id}/relations", params.to_json
    end

    it 'should return 201 (created)' do
      expect(last_response.status).to eq(201)
    end

    it 'should have created a new relation' do
      # reflexive relations + created one
      expect(Relation.count).to eq 3
    end

    it_behaves_like 'creates the relation'

    context 'relation that would create a circular scheduling dependency' do
      let(:from_child) do
        FactoryBot.create(:work_package, parent: from)
      end
      let(:to_child) do
        FactoryBot.create(:work_package, parent: to)
      end
      let(:children_follows_relation) do
        FactoryBot.create :relation,
                          from: to_child,
                          to: from_child,
                          relation_type: Relation::TYPE_FOLLOWS
      end
      let(:relation_type) { Relation::TYPE_FOLLOWS }
      let(:setup) do
        children_follows_relation
      end

      it 'responds with error' do
        expect(last_response.status).to eql 422
      end

      it 'states the reason for the error' do
        expect(last_response.body)
          .to be_json_eql(I18n.t(:'activerecord.errors.messages.circular_dependency').to_json)
          .at_path('message')
      end
    end

    context "'relates to' relation that would create a circular dependency" do
      let(:work_package_a) { FactoryBot.create(:work_package) }
      let(:work_package_b) { FactoryBot.create(:work_package, project: work_package_a.project) }
      let(:work_package_c) { FactoryBot.create(:work_package, project: work_package_b.project) }
      let(:relation_a_b) do
        FactoryBot.create(:relation,
                          from: work_package_a,
                          to: work_package_b,
                          relation_type: Relation::TYPE_RELATES)
      end
      let(:relation_b_c) do
        FactoryBot.create(:relation,
                          from: work_package_b,
                          to: work_package_c,
                          relation_type: Relation::TYPE_RELATES)
      end

      let!(:from) { work_package_c }
      let!(:to) { work_package_a }

      let(:type) { Relation::TYPE_RELATES }

      let(:setup) do
        relation_a_b
        relation_b_c
      end

      it 'returns 201 (created) and creates the relation with an inverted direction' do
        expect(last_response.status)
          .to eq(201)

        expect(Relation.direct.count).to eq 3

        new_relation = Relation.direct.last

        expect(new_relation.to)
          .to eql work_package_c

        expect(new_relation.from)
          .to eql work_package_a
      end
    end

    context 'follows relation within siblings' do
      let(:sibling) do
        FactoryBot.create(:work_package)
      end
      let(:other_sibling) do
        FactoryBot.create(:work_package)
      end
      let(:parent) do
        wp = FactoryBot.create(:work_package)

        wp.children = [sibling, from, to, other_sibling]
      end
      let(:existing_follows) do
        FactoryBot.create(:relation, relation_type: 'follows', from: to, to: sibling)
        FactoryBot.create(:relation, relation_type: 'follows', from: other_sibling, to: from)
      end

      let(:setup) do
        parent
        existing_follows
      end

      it_behaves_like 'creates the relation'
    end

    context 'follows relation to sibling\'s child' do
      let(:sibling) do
        FactoryBot.create(:work_package)
      end
      let(:sibling_child) do
        FactoryBot.create(:work_package, parent: sibling)
      end
      let(:parent) do
        wp = FactoryBot.create(:work_package)

        wp.children = [sibling, from, to]
      end
      let(:existing_follows) do
        FactoryBot.create(:relation, relation_type: 'follows', from: to, to: sibling_child)
      end

      let(:setup) do
        parent
        existing_follows
      end

      it_behaves_like 'creates the relation'
    end
  end

  describe "updating a relation" do
    let(:new_description) { "This is another description" }
    let(:new_delay) { 42 }

    let(:update) do
      {
        description: new_description,
        delay: new_delay
      }
    end

    before do
      relation

      header "Content-Type", "application/json"
      patch "/api/v3/relations/#{relation.id}", update.to_json
    end

    it "should return 200 (ok)" do
      expect(last_response.status).to eq 200
    end

    it "updates the relation's description" do
      expect(relation.reload.description).to eq new_description
    end

    it "updates the relation's delay" do
      expect(relation.reload.delay).to eq new_delay
    end

    it "should return the updated relation" do
      rel = ::API::V3::Relations::RelationPayloadRepresenter.new(Relation.new, current_user: user).from_json last_response.body

      expect(rel).to eq relation.reload
    end

    context "with invalid type" do
      let(:update) do
        {
          type: "foobar"
        }
      end

      it "should return 422" do
        expect(last_response.status).to eq 422
      end

      it "should indicate an error with the type attribute" do
        attr = JSON.parse(last_response.body).dig "_embedded", "details", "attribute"

        expect(attr).to eq "type"
      end
    end

    context "with trying to change an immutable attribute" do
      let(:other_wp) { FactoryBot.create :work_package }

      let(:update) do
        {
          _links: {
            from: {
              href: "/api/v3/work_packages/#{other_wp.id}"
            }
          }
        }
      end

      it "should return 422" do
        expect(last_response.status).to eq 422
      end

      it "should indicate an error with the `from` attribute" do
        attr = JSON.parse(last_response.body).dig "_embedded", "details", "attribute"

        expect(attr).to eq "from"
      end

      it "should let the user know the attribute is read-only" do
        msg = JSON.parse(last_response.body)["message"]

        expect(msg).to include "Work package an existing relation's `from` link is immutable"
      end
    end
  end

  describe "permissions" do
    let(:user) { FactoryBot.create :user }

    let(:permissions) { %i(view_work_packages manage_work_package_relations) }

    let(:role) do
      FactoryBot.create :existing_role, permissions: permissions
    end

    let(:project) { FactoryBot.create :project }

    let!(:from) { FactoryBot.create :work_package, project: project }
    let!(:to) { FactoryBot.create :work_package, project: project }

    before do
      project.add_member! user, role

      header "Content-Type", "application/json"
      post "/api/v3/work_packages/#{from.id}/relations", params.to_json
    end

    context "with the required permissions" do
      it "works" do
        expect(last_response.status).to eq 201
      end
    end

    context "without manage_work_package_relations" do
      let(:permissions) { [:view_work_packages] }

      it "is forbidden" do
        expect(last_response.status).to eq 403
      end
    end

    ##
    # This one is expected to fail (422) because the `to` work package
    # is in another project for which the user does not have permission to
    # view work packages.
    context "without manage_work_package_relations" do
      let!(:to) { FactoryBot.create :work_package }

      it "should return 422" do
        expect(last_response.status).to eq 422
      end

      it "should indicate an error with the `to` attribute" do
        attr = JSON.parse(last_response.body).dig "_embedded", "details", "attribute"

        expect(attr).to eq "to"
      end

      it "should have a localized error message" do
        message = JSON.parse(last_response.body)["message"]

        expect(message).not_to include "translation missing"
      end
    end
  end

  describe "deleting a relation" do
    let(:path) do
      api_v3_paths.relation(relation.id)
    end

    let(:permissions) { %i[view_work_packages manage_work_package_relations] }
    let(:role) { FactoryBot.create(:role, permissions: permissions) }

    let(:current_user) do
      FactoryBot.create(:user).tap do |user|
        FactoryBot.create(:member,
                          project: to.project,
                          user: user,
                          roles: [role])
        FactoryBot.create(:member,
                          project: from.project,
                          user: user,
                          roles: [role])
      end
    end

    before do
      delete path
    end

    it "should return 204 and destroy the relation" do
      expect(last_response.status).to eq 204
      expect(Relation.exists?(relation.id)).to be_falsey
    end

    context 'lacking the permission' do
      let(:permissions) { %i[view_work_packages] }

      it 'returns 403' do
        expect(last_response.status).to eq 403
      end

      it 'leaves the relation' do
        expect(Relation.exists?(relation.id)).to be_truthy
      end
    end
  end

  describe 'GET /api/v3/relations?[filter]' do
    let(:user) { FactoryBot.create(:user) }
    let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }
    let(:member_project_to) do
      FactoryBot.build(:member,
                       project: to.project,
                       user: user,
                       roles: [role])
    end

    let(:member_project_from) do
      FactoryBot.build(:member,
                       project: from.project,
                       user: user,
                       roles: [role])
    end
    let(:invisible_relation) do
      invisible_wp = FactoryBot.create(:work_package)

      FactoryBot.create :relation,
                        from: from,
                        to: invisible_wp
    end
    let(:other_visible_work_package) do
      FactoryBot.create(:work_package,
                        project: to.project,
                        type: to.type)
    end
    let(:other_visible_relation) do
      FactoryBot.create :relation,
                        from: to,
                        to: other_visible_work_package
    end

    let(:members) { [member_project_to, member_project_from] }
    let(:filter) do
      [{ involved: { operator: '=', values: [from.id.to_s] } }]
    end

    before do
      members.each(&:save!)
      relation
      invisible_relation
      other_visible_relation

      get "#{api_v3_paths.relations}?filters=#{CGI::escape(JSON::dump(filter))}"
    end

    it 'returns 200' do
      expect(last_response.status).to eql 200
    end

    it 'returns the visible relation (and only the visible one) satisfying the filter' do
      expect(last_response.body)
        .to be_json_eql('1')
        .at_path('total')

      expect(last_response.body)
        .to be_json_eql('1')
        .at_path('count')

      expect(last_response.body)
        .to be_json_eql(relation.id.to_json)
        .at_path('_embedded/elements/0/id')
    end
  end

  describe 'GET /api/v3/relations/:id' do
    let(:path) do
      api_v3_paths.relation(relation.id)
    end

    let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }

    let(:current_user) do
      FactoryBot.create(:user).tap do |user|
        FactoryBot.create(:member,
                          project: to.project,
                          user: user,
                          roles: [role])
        FactoryBot.create(:member,
                          project: from.project,
                          user: user,
                          roles: [role])
      end
    end

    before do
      get path
    end

    context 'for a relation with visible work packages' do
      it 'returns 200' do
        expect(last_response.status).to eql 200
      end

      it 'returns the relation' do
        # Creation leads to journal creation which leads to touching the work package which is not
        # reflected in the value returned from the wp factory.
        from.reload
        to.reload

        expected = API::V3::Relations::RelationRepresenter.new(relation,
                                                               current_user: current_user,
                                                               embed_links: true).to_json

        expect(last_response.body)
          .to be_json_eql expected
      end
    end

    context 'for a relation with an invisible work package' do
      let(:invisible_relation) do
        invisible_wp = FactoryBot.create(:work_package)

        FactoryBot.create :relation,
                          from: from,
                          to: invisible_wp
      end

      let(:path) do
        api_v3_paths.relation(invisible_relation.id)
      end

      it 'returns 404 NOT FOUND' do
        expect(last_response.status).to eql 404
      end
    end
  end
end
