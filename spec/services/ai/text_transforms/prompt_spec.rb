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

  it "puts the scaffold first, the action prompt second and the content into the user message" do
    messages = described_class.build(action:, context: AI::TextTransforms::Context.none, content:)

    expect(messages.system).to eq("#{described_class::SCAFFOLD}\n\nFix grammar only.")
    expect(messages.user).to eq(content)
  end

  it "appends the template only when the action injects it" do
    type = create(:type)
    type.default_variant.update!(default_work_package_description: "## Steps\n\n## Expected")
    project = create(:project, types: [type])
    context = AI::TextTransforms::Context.for_new_work_package(project:, type:)

    plain = described_class.build(action:, context:, content:)
    expect(plain.system).not_to include("## Steps")

    action.usage_scope = "all_work_package_types"
    action.injects_type_template = true
    injected = described_class.build(action:, context:, content:)
    expect(injected.system).to end_with("\n\n#{described_class::TEMPLATE_INTRO}\n## Steps\n\n## Expected")
  end

  it "never interpolates the content into the system message" do
    content = described_class::SCAFFOLD
    messages = described_class.build(action:, context: AI::TextTransforms::Context.none, content:)

    expect(messages.system.scan(described_class::SCAFFOLD).size).to eq(1)
  end
end
