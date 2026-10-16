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

RSpec.describe AI::TextTransforms::Prompt do
  let(:action) { build(:ai_text_transform_action, prompt: "Fix grammar only.") }
  let(:content) { "Login page dont work." }
  let(:no_context) { AI::TextTransforms::Context.none }

  it "puts the scaffold first and the action prompt second" do
    messages = described_class.build(action:, context: no_context, content:)

    expect(messages.system).to eq("#{described_class::SCAFFOLD}\n\nFix grammar only.")
  end

  it "passes the content as the user message byte for byte" do
    content = "  Login page dont work.\n\n## Steps\r\n1. Click submit  "
    messages = described_class.build(action:, context: no_context, content:)

    expect(messages.user).to eq(content)
  end

  it "never interpolates the content into the system message" do
    messages = described_class.build(action:, context: no_context, content: described_class::SCAFFOLD)

    expect(messages.system.scan(described_class::SCAFFOLD).size).to eq(1)
  end

  describe "with a type template" do
    shared_let(:type) { create(:type) }
    shared_let(:project) { create(:project, types: [type]) }

    let(:context) { AI::TextTransforms::Context.for_new_work_package(project:, type:) }

    before do
      type.default_variant.update!(default_work_package_description: "## Steps\n\n## Expected")
    end

    it "appends the template when the action injects it" do
      action.usage_scope = "all_work_package_types"
      action.injects_type_template = true

      messages = described_class.build(action:, context:, content:)

      expect(messages.system)
        .to eq("#{described_class::SCAFFOLD}\n\nFix grammar only.\n\n#{described_class::TEMPLATE_INTRO}\n## Steps\n\n## Expected")
    end

    it "leaves the template out when the action does not inject it" do
      messages = described_class.build(action:, context:, content:)

      expect(messages.system).not_to include("## Steps")
    end

    it "leaves the template out when the type has none" do
      type.default_variant.update!(default_work_package_description: "")
      action.usage_scope = "all_work_package_types"
      action.injects_type_template = true

      messages = described_class.build(action:, context:, content:)

      expect(messages.system).to eq("#{described_class::SCAFFOLD}\n\nFix grammar only.")
    end
  end
end
