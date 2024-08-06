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

RSpec.describe API::Decorators::LinkObject do
  include API::V3::Utilities::PathHelper

  let(:represented) { API::ParserStruct.new }

  context "minimal constructor call" do
    let(:representer) { described_class.new(represented, property_name: :foo) }

    before do
      represented.foo_id = 1
      without_partial_double_verification do
        allow(api_v3_paths).to receive(:foo) { |id| "/api/v3/foos/#{id}" }
      end
    end

    describe "generation" do
      subject { representer.to_json }

      it { is_expected.to be_json_eql("/api/v3/foos/1".to_json).at_path("href") }
    end

    describe "parsing" do
      subject { represented }

      let(:parsed_hash) do
        {
          "href" => "/api/v3/foos/42"
        }
      end

      it "parses the id from the URL" do
        representer.from_hash parsed_hash
        expect(subject.foo_id).to eql("42")
      end

      context "wrong namespace" do
        let(:parsed_hash) do
          {
            "href" => "/api/v3/bars/42"
          }
        end

        it "throws an error" do
          expect { representer.from_hash parsed_hash }.to raise_error(
            API::Errors::InvalidResourceLink
          )
        end
      end
    end
  end

  context "full constructor call" do
    let(:representer) do
      described_class.new(represented,
                          property_name: :foo,
                          path: :foo_path,
                          namespace: "fuhs",
                          getter: :getter,
                          setter: :"setter=")
    end

    before do
      represented.getter = 1

      without_partial_double_verification do
        allow(api_v3_paths).to receive(:foo_path) { |id| "/api/v3/fuhs/#{id}" }
      end
    end

    describe "generation" do
      subject { representer.to_json }

      it { is_expected.to be_json_eql("/api/v3/fuhs/1".to_json).at_path("href") }
    end

    describe "parsing" do
      subject { represented }

      let(:parsed_hash) do
        {
          "href" => "/api/v3/fuhs/42"
        }
      end

      it "parses the id from the URL" do
        representer.from_hash parsed_hash
        expect(subject.setter).to eql("42")
      end

      context "wrong namespace" do
        let(:parsed_hash) do
          {
            "href" => "/api/v3/foos/42"
          }
        end

        it "throws an error" do
          expect { representer.from_hash parsed_hash }.to raise_error(
            API::Errors::InvalidResourceLink
          )
        end
      end
    end
  end
end
