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

RSpec.describe RemovedJsHelpersHelper do
  describe "#link_to_function" do
    it "returns a valid link" do
      allow(SecureRandom).to receive(:uuid).and_return "uuid"
      expect(helper.link_to_function("blubs", nil))
        .to be_html_eql %{
          <a id="link-to-function-uuid" href="">blubs</a>
        }
    end

    it "adds the provided method to the onclick handler" do
      expect(helper.link_to_function("blubs", "doTheMagic(now)", id: :foo))
        .to be_html_eql %{
          <a id="foo" href="">blubs</a>
        }
    end
  end

  describe "#csp_onclick" do
    it "generates a 'click' event handler for the element" do
      helper.csp_onclick("console.log('hello');", "#my-element")

      expect(helper.content_for(:additional_js_dom_ready)).to eq(<<~JS)
        document.querySelector('#my-element')?.addEventListener('click', function(event) {
          console.log('hello');
          event.preventDefault();
        });
      JS
    end

    it "generates a 'click' event handler for the element that does not call event.preventDefault()" do
      helper.csp_onclick("console.log('hello');", "#my-element", prevent_default: false)

      expect(helper.content_for(:additional_js_dom_ready)).to eq(<<~JS)
        document.querySelector('#my-element')?.addEventListener('click', function(event) {
          console.log('hello');
        });
      JS
    end

    it "escapes selector" do
      helper.csp_onclick("console.log('hello');", "[data-attr^='foo']")

      expect(helper.content_for(:additional_js_dom_ready)).to eq(<<~JS)
        document.querySelector('[data-attr^=\\'foo\\']')?.addEventListener('click', function(event) {
          console.log('hello');
          event.preventDefault();
        });
      JS
    end
  end
end
