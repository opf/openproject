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

RSpec.describe AI::Assistance::OutputRules do
  subject(:rules) { described_class.new(skill, locale: "de").to_s }

  let(:skill) { build(:ai_assistant_skill, answer_format:, proposal_scope:) }
  let(:answer_format) { "text" }
  let(:proposal_scope) { "changes" }

  it "sets the answer language and guards against instructions in the context" do
    expect(rules).to include(%(Write "answer" in Markdown, in the language with the locale code "de".))
    expect(rules).to end_with(described_class::GUARD)
  end

  it "explains the change fields for a skill that may propose changes" do
    expect(rules).to include(described_class::FIELDS, described_class::FORMATTING)
  end

  context "with the comment-only scope" do
    let(:proposal_scope) { "comment_only" }

    it "allows a comment only" do
      expect(rules).to include(%(Propose a "comment" only))
      expect(rules).not_to include(described_class::FIELDS)
    end
  end

  context "with the read-only scope" do
    let(:proposal_scope) { "read_only" }

    it "allows no changes" do
      expect(rules).to include(%(Use an empty "proposals" list.))
      expect(rules).not_to include(described_class::FIELDS)
    end
  end

  context "with a run skill" do
    let(:answer_format) { "findings" }

    it "talks about findings" do
      expect(rules).to include(%(sum up the findings, and the text of each finding, in the language with the locale code "de".))
      expect(rules).to include("A finding can propose changes")
      expect(rules).to include("Each change is only a proposal")
    end
  end

  context "with a skill with findings, in a follow-up turn" do
    subject(:rules) { described_class.new(skill, locale: "de", format: "text").to_s }

    let(:answer_format) { "findings" }

    it "uses the rules of a free answer" do
      expect(rules).to include(%(Write "answer" in Markdown), %(Put proposed changes in "proposals"))
      expect(rules).not_to include("finding")
    end
  end
end
