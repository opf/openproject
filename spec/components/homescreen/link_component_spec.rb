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

require "rails_helper"

RSpec.describe Homescreen::LinkComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  subject(:rendered_component) do
    render_component(link:)
  end

  context "with a blank link" do
    it "does not render" do
      expect(render_component(link: nil).to_s).to be_empty
      expect(render_component(link: {}).to_s).to be_empty
    end
  end

  context "with a link with :url being blank" do
    it "does not render" do
      expect(render_component(link: { url: nil }).to_s).to be_empty
      expect(render_component(link: { url: "" }).to_s).to be_empty
    end
  end

  context "with a link with :url being set" do
    let(:link) { { url: "https://www.openproject.org/docs/", label: :user_guides, icon: "milestone" } }

    it "renders the link using :url" do
      render_component(link:)
      expect(page).to have_link "User guides", href: "https://www.openproject.org/docs/"
    end
  end

  context "with a link with :url_key being set" do
    let(:link) { { url_key: :user_guides, label: :user_guides, icon: "milestone" } }

    it "renders the link using the url from static links" do
      render_component(link:)
      expect(page).to have_link "User guides", href: OpenProject::Static::Links.url_for(link[:url_key])
    end
  end

  context "with a link with :url_key being set to a key not referenced in static links" do
    let(:link) { { url_key: :non_existent_key } }

    it "does not render" do
      expect(render_component(link:).to_s).to be_empty
    end
  end

  context "with both :url and :url_key being set" do
    let(:link) do
      { url: "https://www.openproject.org/i_am_the_url/",
        url_key: :user_guides,
        label: :user_guides,
        icon: "milestone" }
    end

    it "renders the link using :url" do
      render_component(link:)
      expect(page).to have_link "User guides", href: link[:url]
    end
  end
end
