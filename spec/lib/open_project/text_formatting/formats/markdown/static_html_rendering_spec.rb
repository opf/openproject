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

RSpec.describe "Markdown static-HTML rendering" do # rubocop:disable RSpec/DescribeClass
  subject(:formatted) { render(input) }

  def render(text)
    OpenProject::TextFormatting::Renderer.format_text(
      text,
      format: :rich,
      **context.merge(static_html: true)
    )
  end

  let(:context) { { only_path: false } }

  shared_let(:project) { create(:project, identifier: "demo") }
  shared_let(:type) { create(:type, name: "Task") }
  shared_let(:status) { create(:status, name: "New") }
  shared_let(:work_package) do
    create(:work_package, project:, type:, status:, subject: "Cats V Dogs")
  end
  shared_let(:admin) { create(:admin) }

  before { login_as(admin) }

  describe "no JS-hydrated custom elements" do
    let(:input) { "see #{'##'}#{work_package.id} for details" }

    it "never emits <opce-macro-wp-quickinfo>" do
      expect(formatted).not_to include("opce-macro-wp-quickinfo")
    end
  end

  describe "basic mention (#N) — no behaviour change" do
    let(:input) { "see ##{work_package.id} please" }

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before { work_package.update_columns(identifier: "DEMO-1", sequence_number: 1) }

      it "renders the formatted_id as an anchor" do
        expect(formatted).to include(">DEMO-1<")
        expect(formatted).to include('href="')
      end
    end
  end

  describe "quickinfo macro (##N) — type + id + subject in static anchor" do
    let(:input) { "see #{'##'}#{work_package.id}" }

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before { work_package.update_columns(identifier: "DEMO-1", sequence_number: 1) }

      it "renders type + formatted_id + subject as a single anchor" do
        expect(formatted).to match(%r{<a\b[^>]*>Task DEMO-1: Cats V Dogs</a>})
      end

      it "links to the work package show path" do
        expect(formatted).to include(%(href="http))
        expect(formatted).to include("/work_packages/DEMO-1")
      end
    end

    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "renders type + #N + subject as a single anchor" do
        expect(formatted).to match(%r{<a\b[^>]*>Task ##{work_package.id}: Cats V Dogs</a>})
      end
    end
  end

  describe "detailed macro (###N) — status + type + id + subject" do
    let(:input) { "see #{'###'}#{work_package.id}" }

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before { work_package.update_columns(identifier: "DEMO-1", sequence_number: 1) }

      it "renders status + type + formatted_id + subject as a single anchor" do
        expect(formatted).to match(%r{<a\b[^>]*>New Task DEMO-1: Cats V Dogs</a>})
      end
    end

    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "renders status + type + #N + subject as a single anchor" do
        expect(formatted).to match(%r{<a\b[^>]*>New Task ##{work_package.id}: Cats V Dogs</a>})
      end
    end
  end

  describe "inaccessible work package" do
    shared_let(:other_project) { create(:project, identifier: "secret") }
    shared_let(:reader_role) { create(:project_role, permissions: %i[view_work_packages]) }
    shared_let(:reader) { create(:user, member_with_roles: { project => reader_role }) }
    shared_let(:hidden_wp) do
      create(:work_package, project: other_project, type:, status:, subject: "Hidden")
    end

    before { login_as(reader) }

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before { hidden_wp.update_columns(identifier: "SECRET-1", sequence_number: 1) }

      it "renders the bare identifier label without an anchor for ##N" do
        rendered = render("see #{'##'}#{hidden_wp.id}")
        expect(rendered).to include("SECRET-1")
        expect(rendered).not_to match(%r{<a[^>]*>[^<]*SECRET-1})
        expect(rendered).not_to include("Hidden")
      end

      it "renders the bare identifier label without an anchor for ###N" do
        rendered = render("see #{'###'}#{hidden_wp.id}")
        expect(rendered).to include("SECRET-1")
        expect(rendered).not_to match(%r{<a[^>]*>[^<]*SECRET-1})
      end
    end

    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "renders the bare #N label without an anchor for ##N" do
        rendered = render("see #{'##'}#{hidden_wp.id}")
        expect(rendered).to include("##{hidden_wp.id}")
        expect(rendered).not_to match(%r{<a[^>]*>[^<]*##{hidden_wp.id}})
        expect(rendered).not_to include("Hidden")
      end

      it "renders the bare #N label without an anchor for ###N" do
        rendered = render("see #{'###'}#{hidden_wp.id}")
        expect(rendered).to include("##{hidden_wp.id}")
        expect(rendered).not_to match(%r{<a[^>]*>[^<]*##{hidden_wp.id}})
      end
    end
  end

  describe "work-package mention envelope" do
    let(:mention_attrs) do
      %(class="mention" data-id="#{work_package.id}" data-type="work_package" data-display-id="DEMO-1")
    end
    let(:input) { %(check <mention #{mention_attrs}>##DEMO-1</mention>) }

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before { work_package.update_columns(identifier: "DEMO-1", sequence_number: 1) }

      it "renders ## quickinfo envelopes as a static anchor with type + id + subject" do
        expect(formatted).to match(%r{<a\b[^>]*>Task DEMO-1: Cats V Dogs</a>})
        expect(formatted).not_to include("opce-macro-wp-quickinfo")
      end
    end
  end

  # Public document exports and other non-authenticated rendering paths
  # invoke the static-HTML pipeline with `User.current == User.anonymous`.
  # In that context every non-public WP is invisible, so any mention must
  # collapse to its current `formatted_id` as plain text — no anchor, no
  # subject leak.
  describe "anonymous current_user" do
    shared_let(:private_project) { create(:project, identifier: "private", public: false) }
    shared_let(:private_wp) do
      create(:work_package, project: private_project, type:, status:, subject: "Top Secret")
    end

    around do |example|
      User.execute_as(User.anonymous) { example.run }
    end

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      before { private_wp.update_columns(identifier: "PRIVATE-1", sequence_number: 1) }

      it "does not raise and renders the identifier text" do
        expect { render("see #{'##'}#{private_wp.id}") }
          .not_to raise_error

        rendered = render("see #{'##'}#{private_wp.id}")
        expect(rendered).to include("PRIVATE-1")
      end
    end

    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "does not raise and renders the #N text" do
        expect { render("see #{'##'}#{private_wp.id}") }
          .not_to raise_error

        rendered = render("see #{'##'}#{private_wp.id}")
        expect(rendered).to include("##{private_wp.id}")
      end
    end
  end
end
