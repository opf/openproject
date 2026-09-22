# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# This program is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
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
require Rails.root.join(".github/dangerfiles/html_safe/scanner")

RSpec.describe HtmlSafeDangerScanner do
  describe ".skip_path?" do
    it "skips root spec, lookbook, docs, and dangerfiles" do
      expect(described_class.skip_path?("spec/models/foo_spec.rb")).to be(true)
      expect(described_class.skip_path?("lookbook/previews/foo.rb")).to be(true)
      expect(described_class.skip_path?("docs/api.md")).to be(true)
      expect(described_class.skip_path?(".github/dangerfiles/html_safe/scanner.rb")).to be(true)
    end

    it "skips module spec paths" do
      expect(described_class.skip_path?("modules/storages/spec/features/foo_spec.rb")).to be(true)
    end

    it "does not skip production code" do
      expect(described_class.skip_path?("app/helpers/foo.rb")).to be(false)
      expect(described_class.skip_path?("modules/storages/app/helpers/foo.rb")).to be(false)
    end
  end

  describe ".added_non_empty_html_safe_line?" do
    it "ignores diff headers" do
      expect(described_class.added_non_empty_html_safe_line?("+++ b/app/models/foo.rb")).to be(false)
    end

    it "ignores removed lines" do
      expect(described_class.added_non_empty_html_safe_line?("- foo.html_safe")).to be(false)
    end

    it "ignores empty-string buffers" do
      expect(described_class.added_non_empty_html_safe_line?('+ buffer = "".html_safe')).to be(false)
      expect(described_class.added_non_empty_html_safe_line?("+ buffer = ''.html_safe")).to be(false)
    end

    it "ignores html_safe? and html_safe_gsub" do
      expect(described_class.added_non_empty_html_safe_line?("+ foo.html_safe?")).to be(false)
      expect(described_class.added_non_empty_html_safe_line?('+ foo.html_safe_gsub("a", "b")')).to be(false)
    end

    it "flags a non-empty html_safe call" do
      expect(described_class.added_non_empty_html_safe_line?("+ value.html_safe")).to be(true)
    end

    it "flags a non-empty call on the same line as an empty buffer" do
      line = '+ safe_join(["".html_safe, params[:body].html_safe])'

      expect(described_class.added_non_empty_html_safe_line?(line)).to be(true)
    end

    it "does not flag a line of only empty buffers" do
      line = "+ safe_join([''.html_safe, \"\".html_safe])"

      expect(described_class.added_non_empty_html_safe_line?(line)).to be(false)
    end
  end
end
