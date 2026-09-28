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

RSpec.describe API::V3::AI::TextTransformActionRepresenter do
  let(:action) { build_stubbed(:ai_text_transform_action, position: 3, injects_type_template: true) }
  let(:representer) { described_class.new(action, current_user: instance_double(User)) }

  describe "generation" do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json("AITextTransformAction".to_json).at_path("_type") }

    it "fulfills the documented schema" do
      expect(generated).to match_json_schema.from_docs("ai_text_transform_action_model")
    end

    describe "properties" do
      it { is_expected.to be_json_eql(action.id.to_json).at_path("id") }
      it { is_expected.to be_json_eql(action.label.to_json).at_path("label") }
      it { is_expected.to be_json_eql(3.to_json).at_path("position") }
      it { is_expected.to be_json_eql(true.to_json).at_path("injectsTypeTemplate") }
      it { is_expected.not_to have_json_path("prompt") }
    end

    describe "_links" do
      it { is_expected.to have_json_type(Object).at_path("_links") }

      describe "self" do
        it_behaves_like "has a titled link" do
          let(:link) { "self" }
          let(:href) { "/api/v3/ai_text_transform_actions/#{action.id}" }
          let(:title) { action.label }
        end
      end
    end
  end
end
