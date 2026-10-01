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

RSpec.describe RepositoriesHelper do
  let(:project) { build_stubbed(:project) }
  let(:repository) { build_stubbed(:repository_subversion, project:) }
  let(:changeset) { build_stubbed(:changeset, repository:, revision: "42") }

  before do
    assign(:project, project)
    assign(:repository, repository)
    assign(:changeset, changeset)

    allow(repository).to receive(:relative_path) { |path| path }

    allow(helper).to receive_messages(
      show_revisions_path_project_repository_path: "/revisions",
      entry_revision_project_repository_path: "/entry",
      diff_revision_project_repository_path: "/diff"
    )
  end

  describe "#changes_tree_li_element" do
    it "escapes plain text content" do
      malicious_text = '<script>alert("xss")</script>'
      result = helper.changes_tree_li_element("D", malicious_text, "change change-D")

      expect(result).not_to include("<script>")
      expect(result).to include("&lt;script&gt;")
    end

    it "preserves html_safe text content" do
      safe_text = '<a href="/path">file.txt</a>'.html_safe
      result = helper.changes_tree_li_element("A", safe_text, "change change-A")

      expect(result).to include('<a href="/path">file.txt</a>')
    end

    it "escapes malicious content in the style parameter" do
      result = helper.changes_tree_li_element("A", "file.txt", 'change" onclick="alert(1)')

      expect(result).not_to include('onclick="alert(1)"')
      expect(result).to include("onclick=&quot;alert(1)")
    end

    it "sets the correct icon class for each action" do
      expect(helper.changes_tree_li_element("A", "f", "s")).to include("icon-add")
      expect(helper.changes_tree_li_element("D", "f", "s")).to include("icon-delete")
      expect(helper.changes_tree_li_element("C", "f", "s")).to include("icon-copy")
      expect(helper.changes_tree_li_element("R", "f", "s")).to include("icon-rename")
      expect(helper.changes_tree_li_element("M", "f", "s")).to include("icon-arrow-left-right")
    end

    it "sets the title attribute from the action" do
      result = helper.changes_tree_li_element("D", "file.txt", "change")

      expect(result).to include("title=\"#{I18n.t(:label_deleted)}\"")
    end
  end

  describe "#render_changes_tree" do
    def make_change(path:, action:, revision: nil, from_path: nil)
      instance_double(Change, path:, action:, revision:, from_path:).tap do |c|
        allow(c).to receive(:action=)
      end
    end

    it "returns empty string for nil tree" do
      expect(helper.render_changes_tree(nil)).to eq("")
    end

    context "with a deleted file containing a malicious name" do
      let(:tree) do
        {
          '/"><img src=x onerror=alert(1)>' => {
            c: make_change(path: '/"><img src=x onerror=alert(1)>', action: "D")
          }
        }
      end

      it "escapes the filename" do
        result = helper.render_changes_tree(tree)
        doc = Nokogiri::HTML.fragment(result)

        expect(doc.at_css("img")).not_to be_present
        li = doc.at_css("li")
        expect(li.text).to include("<img src=x onerror=alert(1)>")
      end
    end

    context "with an added file" do
      let(:tree) do
        {
          "/added_file.txt" => {
            c: make_change(path: "/added_file.txt", action: "A")
          }
        }
      end

      it "renders a link to the file" do
        result = helper.render_changes_tree(tree)

        expect(result).to include("<a")
        expect(result).to include("added_file.txt")
        expect(result).to include("icon-add")
      end
    end

    context "with a modified file" do
      let(:tree) do
        {
          "/modified.txt" => {
            c: make_change(path: "/modified.txt", action: "M")
          }
        }
      end

      it "renders a diff link" do
        result = helper.render_changes_tree(tree)

        expect(result).to include(I18n.t(:label_diff))
        expect(result).to include("icon-arrow-left-right")
      end
    end

    context "with a file with revision" do
      let(:tree) do
        {
          "/file.txt" => {
            c: make_change(path: "/file.txt", action: "A", revision: "abc123")
          }
        }
      end

      it "includes the escaped revision" do
        result = helper.render_changes_tree(tree)

        expect(result).to include("abc123")
      end
    end

    context "with a file with a malicious revision" do
      let(:tree) do
        {
          "/file.txt" => {
            c: make_change(path: "/file.txt", action: "A", revision: '<script>alert("xss")</script>')
          }
        }
      end

      it "escapes the revision" do
        result = helper.render_changes_tree(tree)

        expect(result).not_to include("<script>")
        expect(result).to include("&lt;script&gt;")
      end
    end

    context "with a copied file" do
      let(:tree) do
        {
          "/copied.txt" => {
            c: make_change(path: "/copied.txt", action: "C", from_path: "/original.txt")
          }
        }
      end

      it "renders the from_path in a span" do
        result = helper.render_changes_tree(tree)
        doc = Nokogiri::HTML.fragment(result)

        span = doc.at_css("span.copied-from")
        expect(span).to be_present
        expect(span.text).to eq("/original.txt")
      end
    end

    context "with a copied file with malicious from_path" do
      let(:tree) do
        {
          "/copied.txt" => {
            c: make_change(path: "/copied.txt", action: "C", from_path: "<img src=x onerror=alert(1)>")
          }
        }
      end

      it "escapes the from_path" do
        result = helper.render_changes_tree(tree)
        doc = Nokogiri::HTML.fragment(result)

        expect(doc.at_css("img")).not_to be_present
        span = doc.at_css("span.copied-from")
        expect(span.text).to eq("<img src=x onerror=alert(1)>")
      end
    end

    context "with a folder containing a malicious name" do
      let(:tree) do
        {
          '/"><img src=x onerror=alert(1)>' => {
            s: {
              '/"><img src=x onerror=alert(1)>/file.txt' => {
                c: make_change(path: '/"><img src=x onerror=alert(1)>/file.txt', action: "A")
              }
            }
          }
        }
      end

      it "escapes the folder name in the li element" do
        result = helper.render_changes_tree(tree)
        doc = Nokogiri::HTML.fragment(result)

        expect(doc.at_css("img")).not_to be_present
        folder_link = doc.at_css("li.folder a")
        expect(folder_link.text).to include("<img src=x onerror=alert(1)>")
      end
    end

    context "with a folder" do
      let(:tree) do
        {
          "/src" => {
            s: {
              "/src/file.txt" => {
                c: make_change(path: "/src/file.txt", action: "A")
              }
            }
          }
        }
      end

      it "renders nested ul structure" do
        result = helper.render_changes_tree(tree)
        doc = Nokogiri::HTML.fragment(result)

        expect(doc.css("ul").count).to eq(2)
        expect(doc.css("li").count).to eq(2)
      end

      it "renders a folder link with folder icon" do
        result = helper.render_changes_tree(tree)

        expect(result).to include("icon-folder-add")
        expect(result).to include("folder")
      end
    end
  end
end
