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

RSpec.describe BasicData::AiTextTransformActionSeeder do
  include_context "with basic seed data"

  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

  before do
    seeder.seed!
  end

  context "with some text transform actions defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        ai_text_transform_actions:
        - reference: :ai_action_fix_grammar
          label: Fix grammar
          usage_scope: everywhere
          position: 1
          prompt: Fix the grammar.
        - reference: :ai_action_sort_into_template
          label: Sort into template
          usage_scope: all_work_package_types
          injects_type_template: true
          position: 2
          prompt: Sort the text into the template.
      SEEDING_DATA_YAML
    end

    it "creates the corresponding actions with the given attributes" do
      expect(AI::TextTransformAction.count).to eq(2)
      expect(AI::TextTransformAction.find_by(label: "Fix grammar")).to have_attributes(
        prompt: "Fix the grammar.",
        usage_scope: "everywhere",
        active: true,
        injects_type_template: false,
        position: 1
      )
      expect(AI::TextTransformAction.find_by(label: "Sort into template")).to have_attributes(
        prompt: "Sort the text into the template.",
        usage_scope: "all_work_package_types",
        active: true,
        injects_type_template: true,
        position: 2
      )
    end

    it "references the actions in the seed data" do
      expect(seed_data.find_reference(:ai_action_fix_grammar))
        .to eq(AI::TextTransformAction.find_by(label: "Fix grammar"))
      expect(seed_data.find_reference(:ai_action_sort_into_template))
        .to eq(AI::TextTransformAction.find_by(label: "Sort into template"))
    end

    context "when seeding a second time" do
      subject(:second_seeder) { described_class.new(second_seed_data) }

      let(:second_seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }

      before do
        second_seeder.seed!
      end

      it "does not create additional actions" do
        expect(AI::TextTransformAction.count).to eq(2)
      end

      it "registers existing matching actions as references in the seed data" do
        expect(second_seed_data.find_reference(:ai_action_fix_grammar))
          .to eq(seed_data.find_reference(:ai_action_fix_grammar))
        expect(second_seed_data.find_reference(:ai_action_sort_into_template))
          .to eq(seed_data.find_reference(:ai_action_sort_into_template))
      end
    end
  end

  context "without text transform actions defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        nothing here: ''
      SEEDING_DATA_YAML
    end

    it "creates no actions" do
      expect(AI::TextTransformAction.count).to eq(0)
    end
  end
end
