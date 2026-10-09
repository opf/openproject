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
      let startedAt = 0;
      let running = false;

      function record() {
        const wrapper = document.querySelector('#wrapper');
        const menu = document.querySelector('#main-menu');
        if (wrapper && menu) {
          window.firstPaintFrames.push({
            time: performance.now(),
            hidden: wrapper.classList.contains('hidden-navigation'),
            width: menu.getBoundingClientRect().width,
            booted: document.body.classList.contains('__ng2-bootstrap-has-run')
          });
        }
        if (performance.now() - startedAt < 4000) {
          requestAnimationFrame(record);
        } else {
          running = false;
        }
      }

      function restart() {
        window.firstPaintFrames = [];
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

  def start_first_paint_sampling
    skip "first-paint sampling needs Cuprite (CDP)" unless using_cuprite?

    page.driver.browser.page.command("Page.addScriptToEvaluateOnNewDocument", source: RECORDER)
  end

  def first_paint_frames
    frames = page.evaluate_script("window.firstPaintFrames")
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
