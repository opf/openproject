# frozen_string_literal: true

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
  end

  context "when running under cuprite" do
    it_behaves_like "blocks until its event fires"
  end

  context "when running under selenium", :selenium do
    it_behaves_like "blocks until its event fires"
  end
end
