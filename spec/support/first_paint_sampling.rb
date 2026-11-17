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

##
# Records, per animation frame, whether the main menu is hidden, starting
# before any page script runs. Cuprite only: it needs the CDP command
# Page.addScriptToEvaluateOnNewDocument.
module FirstPaintSampling
  RECORDER = <<~JS
    (() => {
      const CEILING_MS = 20000;
      const FRAMES_AFTER_BOOT = 5;
      let startedAt = 0;
      let running = false;
      let bodyAtRestart = null;
      let bootedFrames = 0;

      function record() {
        const wrapper = document.querySelector('#wrapper');
        const menu = document.querySelector('#main-menu');
        const rendered = document.body && document.body !== bodyAtRestart;
        if (rendered && wrapper && menu) {
          const booted = document.body.classList.contains('__ng2-bootstrap-has-run');
          window.firstPaintFrames.push({
            time: performance.now(),
            hidden: wrapper.classList.contains('hidden-navigation'),
            width: menu.getBoundingClientRect().width,
            booted
          });
          bootedFrames = booted ? bootedFrames + 1 : 0;
        }
        if (bootedFrames >= FRAMES_AFTER_BOOT || performance.now() - startedAt >= CEILING_MS) {
          running = false;
          window.firstPaintDone = true;
        } else {
          requestAnimationFrame(record);
        }
      }

      function restart() {
        window.firstPaintFrames = [];
        window.firstPaintDone = false;
        bodyAtRestart = document.body;
        bootedFrames = 0;
        startedAt = performance.now();
        if (!running) {
          running = true;
          requestAnimationFrame(record);
        }
      }

      restart();
      document.addEventListener('turbo:before-render', restart);
      window.addEventListener('pageshow', (event) => { if (event.persisted) restart(); });
    })();
  JS

  WAIT_FOR_FRAMES = <<~JS
    const done = arguments[0];
    (function poll() {
      if (window.firstPaintFrames === undefined || window.firstPaintDone) {
        done(window.firstPaintFrames ?? null);
      } else {
        requestAnimationFrame(poll);
      }
    })();
  JS

  def start_first_paint_sampling
    skip "first-paint sampling needs Cuprite (CDP)" unless using_cuprite?

    page.driver.browser.page.command("Page.addScriptToEvaluateOnNewDocument", source: RECORDER)
  end

  # Returns once the recorder has stopped, which it does a few frames after
  # Angular has booted; callers wait for the bootstrap first.
  def first_paint_frames
    frames = page.evaluate_async_script(WAIT_FOR_FRAMES)
    raise "first-paint recorder not installed; call start_first_paint_sampling before navigating" if frames.nil?

    frames
  end

  def menu_hidden_in_every_frame?
    frames = first_paint_frames
    frames.any? && frames.all? { |frame| frame["hidden"] }
  end

  def menu_settles_hidden?
    frames = first_paint_frames
    return false if frames.empty? || !frames.last["hidden"]

    frames.drop_while { |frame| !frame["hidden"] }.all? { |frame| frame["hidden"] }
  end
end
