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
require_module_spec_helper

RSpec.describe AI::Assistance::OutputRules do
  subject(:rules) { described_class.new(skill, locale: "de").to_s }

  let(:skill) { build(:ai_assistant_skill, proposal_scope:) }
  let(:proposal_scope) { "changes" }

  it "sets the answer language, explains proposals, and guards against instructions in the context" do
    expect(rules).to include(%(Write "answer" in Markdown, and the "text" of each proposal, in the language), %(locale code "de"))
    expect(rules).to include(described_class::PROPOSALS)
    expect(rules).to include(%(A finding always uses one of the listed areas, never "none".))
    expect(rules).to end_with(described_class::GUARD)
  end

  it "asks for names instead of pronouns, also off a work package" do
    expect(rules).to include(described_class::PEOPLE)
    expect(described_class.new(skill, locale: "de", work_package: false).to_s).to include(described_class::PEOPLE)
  end

  it "explains the change fields for a skill that may propose changes" do
    expect(rules).to include(described_class::CHANGES, described_class::FIELDS, described_class::FORMATTING)
  end

  it "says that the newest comment wins, only on a work package" do
    expect(rules).to include(described_class::NEWEST_WINS)
    expect(described_class.new(skill, locale: "de", work_package: false).to_s).not_to include(described_class::NEWEST_WINS)
  end

  it "explains the tools" do
    expect(rules).to include(described_class::TOOLS)
  end

  context "without tools" do
    subject(:rules) { described_class.new(skill, locale: "de", tools: false).to_s }

    it "does not mention them" do
      expect(rules).not_to include(described_class::TOOLS)
    end
  end

  context "with the comment-only scope" do
    let(:proposal_scope) { "comment_only" }

    it "allows a comment only" do
      expect(rules).to include(%(A proposal can add a "comment" only.))
      expect(rules).not_to include(described_class::FIELDS)
    end
  end

  context "with the read-only scope" do
    let(:proposal_scope) { "read_only" }

    it "allows no changes, but still findings" do
      expect(rules).to include(%(Use an empty "changes" list in every proposal.), described_class::PROPOSALS)
      expect(rules).not_to include(described_class::FIELDS)
    end
  end
end
