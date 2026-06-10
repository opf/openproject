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

RSpec.describe "Markdown plain-text rendering" do # rubocop:disable RSpec/DescribeClass
  subject(:formatted) { render(input).strip }

  def render(text)
    OpenProject::TextFormatting::Renderer.format_text(text, plain_text: true)
  end

  describe "plain markdown" do
    let(:input) { "Hello *world*" }

    it "renders text without HTML tags" do
      expect(formatted).to eq("Hello world")
    end
  end

  describe "with an inline work-package reference" do
    shared_let(:project) { create(:project, identifier: "demo") }
    shared_let(:work_package) { create(:work_package, project:, subject: "task") }
    shared_let(:admin) { create(:admin) }

    let(:input) { "see ##{work_package.id} please" }

    before { login_as(admin) }

    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "renders the hash-prefixed numeric id" do
        expect(formatted).to eq("see ##{work_package.id} please")
      end
    end

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before do
        work_package.update_columns(identifier: "DEMO-1", sequence_number: 1)
      end

      it "renders the bare semantic identifier" do
        expect(formatted).to eq("see DEMO-1 please")
      end
    end
  end

  describe "with a quickinfo macro reference" do
    shared_let(:project) { create(:project, identifier: "demo") }
    shared_let(:work_package) { create(:work_package, project:, subject: "task") }
    shared_let(:admin) { create(:admin) }

    before { login_as(admin) }

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before do
        work_package.update_columns(identifier: "DEMO-1", sequence_number: 1)
      end

      it "renders ##N as bare semantic identifier" do
        expect(render("see #{'##'}#{work_package.id} please").strip).to eq("see DEMO-1 please")
      end

      it "renders ###N as bare semantic identifier" do
        expect(render("see #{'###'}#{work_package.id} please").strip).to eq("see DEMO-1 please")
      end
    end

    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "renders ##N as the hash-prefixed numeric id" do
        expect(render("see #{'##'}#{work_package.id} please").strip).to eq("see ##{work_package.id} please")
      end

      it "renders ###N as the hash-prefixed numeric id" do
        expect(render("see #{'###'}#{work_package.id} please").strip).to eq("see ##{work_package.id} please")
      end
    end
  end

  describe "with a work-package mention envelope" do
    shared_let(:project) { create(:project, identifier: "demo") }
    shared_let(:work_package) { create(:work_package, project:, subject: "task") }
    shared_let(:admin) { create(:admin) }

    let(:mention_attrs) do
      %(class="mention" data-id="#{work_package.id}" data-type="work_package" data-display-id="DEMO-1")
    end
    let(:input) { %(check <mention #{mention_attrs}>#DEMO-1</mention>) }

    before { login_as(admin) }

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before do
        work_package.update_columns(identifier: "DEMO-1", sequence_number: 1)
      end

      it "unwraps to the bare semantic identifier" do
        expect(formatted).to eq("check DEMO-1")
      end
    end

    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "unwraps to the hash-prefixed numeric id" do
        expect(formatted).to eq("check ##{work_package.id}")
      end
    end

    context "with a ##-shaped mention text in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:input) { %(check <mention #{mention_attrs}>##DEMO-1</mention>) }

      before do
        work_package.update_columns(identifier: "DEMO-1", sequence_number: 1)
      end

      it "unwraps to the bare semantic identifier" do
        expect(formatted).to eq("check DEMO-1")
      end
    end
  end
end
