#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Relations::RelationRepresenter, type: :request do
  let(:user) { FactoryGirl.create :admin }

  let!(:from) { FactoryGirl.create :work_package }
  let!(:to) { FactoryGirl.create :work_package }

  let(:type) { "precedes" }
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

  before do
    login_as user
  end

  describe "creating a relation" do
    before do
      expect(Relation.count).to eq 0

      post "/api/v3/relations",
           params: params.to_json,
           headers: { "Content-Type": "application/json" }
    end

    it 'should return 201 (created)' do
      expect(response.status).to eq(201)
    end

    it 'should have created a new relation' do
      expect(Relation.count).to eq 1
    end

    it 'should have created the relation correctly' do
      rel = described_class.new(Relation.new, current_user: user).from_json response.body

      expect(rel.from).to eq from
      expect(rel.to).to eq to
      expect(rel.relation_type).to eq type
      expect(rel.description).to eq description
      expect(rel.delay).to eq delay
    end
  end

  describe "updating a relation" do
    let!(:relation) do
      FactoryGirl.create :relation,
                         from: from,
                         to: to,
                         relation_type: type,
                         description: description,
                         delay: delay
    end

    let(:new_description) { "This is another description" }
    let(:new_delay) { 42 }

    let(:update) do
      {
        description: new_description,
        delay: new_delay
      }
    end

    before do
      patch "/api/v3/relations/#{relation.id}",
            params: update.to_json,
            headers: { "Content-Type": "application/json" }
    end

    it "should return 200 (ok)" do
      expect(response.status).to eq 200
    end

    it "updates the relation's description" do
      expect(relation.reload.description).to eq new_description
    end

    it "updates the relation's delay" do
      expect(relation.reload.delay).to eq new_delay
    end

    it "should return the updated relation" do
      rel = described_class.new(Relation.new, current_user: user).from_json response.body

      expect(rel).to eq relation.reload
    end

    context "with invalid type" do
      let(:update) do
        {
          type: "foobar"
        }
      end

      it "should return 422" do
        expect(response.status).to eq 422
      end

      it "should indicate an error with the type attribute" do
        attr = JSON.parse(response.body).dig "_embedded", "details", "attribute"

        expect(attr).to eq "type"
      end
    end
  end
end
