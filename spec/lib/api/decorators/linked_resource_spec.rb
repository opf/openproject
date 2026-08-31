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

RSpec.describe API::Decorators::LinkedResource do
  let(:representer) do
    Class.new(API::Decorators::Single) do
      include API::Decorators::LinkedResource

      resource_link :foo,
                    getter: -> { represented["foo"] },
                    setter: ->(fragment:, **) { represented["foo"] = fragment["href"] }
    end
  end
  let(:represented) { {} }
  let(:current_user) { create(:user) }

  describe "embedded links" do
    let(:thing_representer_class) do
      Class.new(API::Decorators::Single) do
        property :id
        def _type = "Thing"
      end
    end

    let(:representer_class) do
      klass = thing_representer_class
      Class.new(API::Decorators::Single) do
        include API::Decorators::LinkedResource

        associated_resource :included_thing, v3_path: :user, representer: klass
        associated_resource :excluded_thing, v3_path: :user, representer: klass
      end
    end

    let(:included_thing) { Struct.new(:id, :name).new(1, "Included thing") }
    let(:excluded_thing) { Struct.new(:id, :name).new(2, "Excluded thing") }
    let(:model) do
      Struct
        .new(:included_thing_id, :included_thing, :excluded_thing_id, :excluded_thing)
        .new(included_thing.id, included_thing, excluded_thing.id, excluded_thing)
    end

    subject(:json) do
      representer_class
        .new(model, current_user:, embed_links: %i[included_thing])
        .to_json
    end

    it "embeds only the selected links" do
      expect(json).to have_json_path("_embedded/includedThing")
      expect(json).not_to have_json_path("_embedded/excludedThing")
    end

    context "when an excluded embedded resource has no readable association" do
      let(:representer_class) do
        klass = thing_representer_class
        Class.new(API::Decorators::Single) do
          include API::Decorators::LinkedResource

          associated_resource :included_thing, v3_path: :user, representer: klass
          associated_resource :excluded_thing,
                              v3_path: :user,
                              representer: klass,
                              link: ->(*) {
                                {
                                  href: "/api/v3/users/#{represented.excluded_thing_id}",
                                  title: "Excluded thing"
                                }
                              }
        end
      end

      let(:model) do
        Class.new do
          attr_reader :included_thing_id, :included_thing, :excluded_thing_id

          def initialize(included_thing, excluded_thing)
            @included_thing_id = included_thing.id
            @included_thing = included_thing
            @excluded_thing_id = excluded_thing.id
          end

          def excluded_thing
            raise "excluded association should not be read"
          end
        end.new(included_thing, excluded_thing)
      end

      it "does not call the excluded association getter" do
        expect { json }.not_to raise_error
      end
    end

    context "with plural associated resources" do
      let(:representer_class) do
        klass = thing_representer_class
        Class.new(API::Decorators::Single) do
          include API::Decorators::LinkedResource

          associated_resources :included_things, v3_path: :user, representer: klass
          associated_resources :excluded_things, v3_path: :user, representer: klass
        end
      end
      let(:model) do
        Struct
          .new(:included_things, :excluded_things)
          .new([included_thing], [excluded_thing])
      end

      subject(:json) do
        representer_class
          .new(model, current_user:, embed_links: %i[included_things])
          .to_json
      end

      it "embeds only the selected collection links" do
        expect(json).to have_json_path("_embedded/includedThings")
        expect(json).not_to have_json_path("_embedded/excludedThings")
      end
    end
  end

  describe ".associated_visible_resource" do
    include API::V3::Utilities::PathHelper

    let(:thing_representer_class) do
      Class.new(API::Decorators::Single) do
        property :id
        def _type = "Thing"
      end
    end

    let(:representer_class) do
      klass = thing_representer_class
      Class.new(API::Decorators::Single) do
        include API::Decorators::LinkedResource
        associated_visible_resource :thing, v3_path: :thing, representer: klass,
                                          undisclosed_title: :"api_v3.undisclosed.parent"
      end
    end

    let(:thing_id) { 42 }
    let(:thing) { double("thing", id: thing_id, name: "Thing Name") }
    let(:model) { Struct.new(:thing_id, :thing).new(thing_id, thing) }

    before do
      without_partial_double_verification do
        allow(api_v3_paths).to receive(:thing).with(thing_id).and_return("/api/v3/things/#{thing_id}")
      end
    end

    subject(:json) { representer_class.new(model, current_user:, embed_links: true).to_json }

    context "when the resource is visible" do
      before { allow(thing).to receive(:visible?).with(current_user).and_return(true) }

      it "renders the link href and title" do
        expect(json).to be_json_eql("/api/v3/things/42".to_json).at_path("_links/thing/href")
        expect(json).to be_json_eql("Thing Name".to_json).at_path("_links/thing/title")
      end

      it "embeds the resource" do
        expect(json).to have_json_path("_embedded/thing")
      end
    end

    context "when the resource is not visible" do
      before { allow(thing).to receive(:visible?).with(current_user).and_return(false) }

      it "renders the link href as undisclosed" do
        expect(json).to be_json_eql(::API::V3::URN_UNDISCLOSED.to_json).at_path("_links/thing/href")
      end

      it "does not embed the resource" do
        expect(json).not_to have_json_path("_embedded/thing")
      end
    end

    context "when the resource id is nil" do
      let(:thing_id) { nil }
      let(:thing) { nil }

      it "renders no link" do
        expect(json).not_to have_json_path("_links/thing")
      end

      it "does not embed the resource" do
        expect(json).not_to have_json_path("_embedded/thing")
      end
    end
  end

  describe "#from_hash" do
    subject { representer.new(represented, current_user:).from_hash(input_hash) }

    let(:input_hash) do
      {
        "_links" => {
          "foo" => { "href" => "https://example.com" }
        }
      }
    end

    it "parses the link" do
      expect { subject }.to change { represented["foo"] }.from(nil).to("https://example.com")
    end

    context "when passing link as string" do
      let(:input_hash) do
        {
          "_links" => {
            "foo" => "https://example.com"
          }
        }
      end

      it "raises an error" do
        expect { subject }.to raise_error(API::Errors::BadRequest)
      end
    end

    context "when passing _links as array" do
      let(:input_hash) do
        {
          "_links" => [
            { "foo" => { "href" => "https://example.com" } }
          ]
        }
      end

      it "raises an error" do
        expect { subject }.to raise_error(API::Errors::BadRequest)
      end
    end
  end
end
