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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::JournalFormatter::Cause do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking squashtm]) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:permitted_user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_squashtm] })
  end
  shared_let(:unpermitted_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  let(:instance) { described_class.new(build(:work_package_journal, journable: work_package)) }
  let(:reference) { nil }
  let(:cause) do
    Journal::CausedBySquashTMRequirementLinked
      .new(requirement_id: 11, requirement_name: "<b>Sign in</b> & out", requirement_reference: reference)
      .to_hash
  end

  def render_as(user, cause, html:)
    User.execute_as(user) { instance.render("cause", [nil, cause], html:) }
  end

  it "accepts the SquashTM cause types" do
    expect(Journal::VALID_CAUSE_TYPES).to include("squashtm_requirement_linked", "squashtm_requirement_unlinked")
  end

  it "renders the HTML variant with an escaped requirement name" do
    expect(render_as(permitted_user, cause, html: true))
      .to eq("<strong>SquashTM requirement linked:</strong> &lt;b&gt;Sign in&lt;/b&gt; &amp; out")
  end

  it "renders the plain text variant" do
    expect(render_as(permitted_user, cause, html: false)).to eq("SquashTM requirement linked: <b>Sign in</b> & out")
  end

  it "renders the unlinked variant" do
    unlinked = Journal::CausedBySquashTMRequirementUnlinked.new(requirement_id: 11, requirement_name: "Sign in").to_hash

    expect(render_as(permitted_user, unlinked, html: false)).to eq("SquashTM requirement unlinked: Sign in")
  end

  context "with a requirement reference" do
    let(:reference) { "REQ-<1>" }

    it "renders the escaped reference before the name" do
      expect(render_as(permitted_user, cause, html: true))
        .to eq("<strong>SquashTM requirement linked:</strong> REQ-&lt;1&gt; – &lt;b&gt;Sign in&lt;/b&gt; &amp; out")
    end

    it "renders the plain text variant" do
      expect(render_as(permitted_user, cause, html: false))
        .to eq("SquashTM requirement linked: REQ-<1> – <b>Sign in</b> & out")
    end
  end

  context "for a user who cannot view the SquashTM test results" do
    let(:reference) { "REQ-001" }

    it "renders only the id of the requirement, without name or reference" do
      expect(render_as(unpermitted_user, cause, html: true)).to eq("<strong>SquashTM requirement linked:</strong> ID 11")
      expect(render_as(unpermitted_user, cause, html: false)).to eq("SquashTM requirement linked: ID 11")
    end

    it "does not leak the name or the reference" do
      rendered = render_as(unpermitted_user, cause, html: true)

      expect(rendered).not_to include("Sign in", "REQ-001")
    end
  end
end
