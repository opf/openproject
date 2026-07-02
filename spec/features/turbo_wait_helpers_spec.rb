# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

# These helpers are driver shims. We assert the *wait mechanism*: the helper must
# not return until its Turbo event has fired. We flip a JS flag on a timer inside
# the block, dispatch the event, then read the flag SYNCHRONOUSLY (no Capybara
# auto-retry) immediately after the helper returns. If the helper no-ops, the flag
# is still false.
RSpec.describe "Turbo wait helpers", :js do
  shared_let(:admin) { create(:admin) }

  before do
    login_as(admin)
    visit home_path
  end

  shared_examples "blocks until its event fires" do
    it "wait_for_turbo_stream returns only after op:turbo-stream-rendered" do
      page.execute_script("window.__turboWaitFlag = false;")
      wait_for_turbo_stream do
        page.execute_script(<<~JS)
          setTimeout(() => {
            window.__turboWaitFlag = true;
            document.dispatchEvent(new CustomEvent('op:turbo-stream-rendered'));
          }, 300);
        JS
      end
      expect(page.evaluate_script("window.__turboWaitFlag")).to be(true)
    end

    it "wait_for_turbo returns only after turbo:load" do
      page.execute_script("window.__turboWaitFlag = false;")
      wait_for_turbo do
        page.execute_script(<<~JS)
          setTimeout(() => {
            window.__turboWaitFlag = true;
            document.dispatchEvent(new CustomEvent('turbo:load'));
          }, 300);
        JS
      end
      expect(page.evaluate_script("window.__turboWaitFlag")).to be(true)
    end

    it "wait_for_turbo_frame returns only after turbo:frame-load" do
      page.execute_script("window.__turboWaitFlag = false;")
      wait_for_turbo_frame do
        page.execute_script(<<~JS)
          setTimeout(() => {
            const el = document.createElement('turbo-frame');
            el.id = 'any_frame';
            document.body.appendChild(el);
            window.__turboWaitFlag = true;
            el.dispatchEvent(new CustomEvent('turbo:frame-load', { bubbles: true }));
          }, 300);
        JS
      end
      expect(page.evaluate_script("window.__turboWaitFlag")).to be(true)
    end

    it "wait_for_turbo_frame(frame:) ignores other frames and waits for the named one" do
      page.execute_script("window.__turboWaitFlag = false;")
      wait_for_turbo_frame(frame: "wanted_frame") do
        page.execute_script(<<~JS)
          // An unrelated frame must NOT satisfy the wait.
          setTimeout(() => {
            const other = document.createElement('turbo-frame');
            other.id = 'other_frame';
            document.body.appendChild(other);
            other.dispatchEvent(new CustomEvent('turbo:frame-load', { bubbles: true }));
          }, 150);
          // The named frame is what we are waiting for.
          setTimeout(() => {
            const wanted = document.createElement('turbo-frame');
            wanted.id = 'wanted_frame';
            document.body.appendChild(wanted);
            window.__turboWaitFlag = true;
            wanted.dispatchEvent(new CustomEvent('turbo:frame-load', { bubbles: true }));
          }, 350);
        JS
      end
      expect(page.evaluate_script("window.__turboWaitFlag")).to be(true)
    end

    it "supports nested waits without clobbering the outer wait" do
      page.execute_script("window.__turboWaitFlag = false;")
      wait_for_turbo_stream do
        # An inner wait for a different event must not delete the outer's
        # pending promise; the outer stream wait still has to resolve.
        wait_for_turbo do
          page.execute_script(<<~JS)
            setTimeout(() => { document.dispatchEvent(new CustomEvent('turbo:load')); }, 150);
          JS
        end
        page.execute_script(<<~JS)
          setTimeout(() => {
            window.__turboWaitFlag = true;
            document.dispatchEvent(new CustomEvent('op:turbo-stream-rendered'));
          }, 150);
        JS
      end
      expect(page.evaluate_script("window.__turboWaitFlag")).to be(true)
    end
  end

  context "when running under cuprite" do
    it_behaves_like "blocks until its event fires"
  end

  context "when running under selenium", :selenium do
    it_behaves_like "blocks until its event fires"
  end
end
