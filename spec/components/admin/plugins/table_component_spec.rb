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

RSpec.describe Admin::Plugins::TableComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(rows: plugins)) }

  def build_plugin(id, **attrs)
    plugin = Redmine::Plugin.send(:new, id)
    attrs.each { |key, value| plugin.public_send(key, value) }
    plugin
  end

  shared_examples_for "rendering Plugins Table headings" do
    include_examples "rendering Border Box Grid heading", text: "Name"
    include_examples "rendering Border Box Grid heading", text: "Author"
    include_examples "rendering Border Box Grid heading", text: "Version"
    include_examples "rendering Border Box Grid mobile heading", text: "Plugins"
  end

  context "with no plugins" do
    let(:plugins) { [] }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Plugins Table headings"
    it_behaves_like "rendering Blank Slate",
                    heading: described_class.new(rows: []).blank_title,
                    icon: :package
  end

  context "with plugins" do
    let(:plugin) do
      build_plugin(:example_plugin,
                   name: "Example Plugin",
                   description: "An example plugin",
                   url: "https://example.com/plugin",
                   author: "Jane Doe",
                   author_url: "https://example.com/jane",
                   version: "1.2.3",
                   bundled: false)
    end
    let(:plugins) { [plugin] }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Plugins Table headings"
    it_behaves_like "rendering Border Box Grid rows", row_count: 1, col_count: 3

    it "renders the plugin's name, description and url", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-row", text: "Example Plugin")
      expect(rendered_component).to have_css(".Box-row", text: "An example plugin")
      expect(rendered_component).to have_link("https://example.com/plugin", href: "https://example.com/plugin")
    end

    it "renders the author as a link to their author_url" do
      expect(rendered_component).to have_link("Jane Doe", href: "https://example.com/jane")
    end

    it "renders the version" do
      expect(rendered_component).to have_css(".Box-row", text: "1.2.3")
    end

    context "when the plugin is bundled" do
      let(:plugin) { build_plugin(:bundled_plugin, name: "Bundled Plugin", version: "1.0.0", bundled: true) }

      it "renders the bundled label instead of the version" do
        expect(rendered_component).to have_css(".Box-row", text: "(Bundled)")
      end
    end

    context "when the plugin has no author_url" do
      let(:plugin) { build_plugin(:no_author_url_plugin, name: "No Author URL Plugin", author: "John Smith") }

      it "renders the author as plain text", :aggregate_failures do
        expect(rendered_component).to have_css(".Box-row", text: "John Smith")
        expect(rendered_component).to have_no_link("John Smith")
      end
    end
  end
end
