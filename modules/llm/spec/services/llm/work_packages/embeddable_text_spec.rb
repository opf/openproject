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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Llm::WorkPackages::EmbeddableText do
  describe ".for" do
    let(:work_package) { build_stubbed(:work_package, subject: "Fix login bug", description:) }

    context "with plain text description" do
      let(:description) { "Users cannot log in after password reset." }

      it "joins subject and description with a newline" do
        expect(described_class.for(work_package)).to eq("Fix login bug\nUsers cannot log in after password reset.")
      end
    end

    context "with HTML description" do
      let(:description) { "<p>Users <strong>cannot</strong> log in.</p>" }

      it "strips HTML tags" do
        expect(described_class.for(work_package)).to eq("Fix login bug\nUsers cannot log in.")
      end
    end

    context "with an HTML table in the description" do
      let(:description) do
        "<p>Intro</p><table><tr><th>Name</th><th>Status</th></tr><tr><td>Login</td><td>broken</td></tr></table>"
      end

      it "keeps the cell contents as separate words" do
        expect(described_class.for(work_package)).to eq("Fix login bug\nIntro Name Status Login broken")
      end
    end

    context "with a multi-line markdown description" do
      let(:description) { "### Steps to reproduce\n\n1. Open <strong>Settings</strong>\n2. Save" }

      it "keeps the line breaks" do
        expect(described_class.for(work_package))
          .to eq("Fix login bug\n### Steps to reproduce\n\n1. Open Settings\n2. Save")
      end
    end

    context "with nil description" do
      let(:description) { nil }

      it "uses only the subject" do
        expect(described_class.for(work_package)).to eq("Fix login bug")
      end
    end
  end
end
