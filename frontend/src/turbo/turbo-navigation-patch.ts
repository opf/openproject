//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

/* eslint-disable */
// @ts-nocheck -- reaches into Turbo's internal FrameController, which is not
// part of the public type surface, so every access below is untyped.
import * as Turbo from '@hotwired/turbo';

// Turbo marks a turbo-frame `busy`/`aria-busy` for the duration of a
// navigation, but for a form-submission-driven navigation it doesn't clear
// that state until well after `proposeVisitIfNavigatedWithAction` below has
// already cloned the frame into the history-cache snapshot -- so the clone
// freezes the frame as permanently busy. `turbo:before-cache` fires too late
// to fix this: by then the clone is already a detached copy, disconnected
// from the live DOM. Exported for direct unit testing.
export function stripStaleBusyState(root: ParentNode): void {
  root.querySelectorAll('turbo-frame[busy]').forEach((frame) => {
    frame.removeAttribute('busy');
    frame.removeAttribute('aria-busy');
  });
}

/**
 * Workaround for https://github.com/hotwired/turbo/issues/1300: with a
 * `<turbo-frame data-turbo-action="advance">`, the URL advances but the
 * browser back button fails to restore the frame's previous content. It only
 * reproduces when the frame is rendered by a Rails view template, which is why
 * there is no upstream frontend regression test — see the Rails system spec.
 *
 * Upstream fix in flight: https://github.com/hotwired/turbo/pull/1549. Once it
 * ships in a release we depend on, drop this patch in favour of it.
 *
 * This is a verbatim fork of `FrameController.proposeVisitIfNavigatedWithAction`
 * with two divergences:
 * - The history snapshot is built from the live document
 *   (`frame.ownerDocument.documentElement.outerHTML`) instead of the fetch
 *   response (`await fetchResponse.responseHTML`), so the restored snapshot
 *   reflects the fully rendered page rather than the bare frame fragment.
 * - `stripStaleBusyState` clears any frame left stuck `busy` in that snapshot
 *   (see its own comment above).
 *
 * Pinned to @hotwired/turbo 8.0.x. `turbo-navigation-patch.spec.ts` is a
 * tripwire: it fails if Turbo renames the patched method or stops sourcing the
 * snapshot from the fetch response (i.e. #1300 looks fixed upstream), at which
 * point this patch should be re-evaluated and likely deleted.
 */
export function applyTurboNavigationPatch() {
  Turbo.FrameElement.delegateConstructor.prototype.proposeVisitIfNavigatedWithAction = function (frame, action = null) {
    this.action = action;

    if (this.action) {
      const pageSnapshot = Turbo.PageSnapshot.fromElement(frame).clone();

      // Form submission cycle:
      // Form marked busy, frame marked busy -> Request starts -> Request Completes -> proposeVisit called ->
      // it caches the pageSnapshot which is still marked busy -> Issues a visit -> visitCachedSnapshot
      // will update the stale pageSnapshot with the current previousFrameElement to keep a fresh copy.
      // But the pageSnapshot busy attribute is untouched. Ideally visitCacheSnapshot would remove the
      // busy attribute from the pageSnapshot, but since that is not happening, the busy state is stripped
      // from the pageSnapshot here.
      stripStaleBusyState(pageSnapshot.element);

      const { visitCachedSnapshot } = frame.delegate;

      // Kept `async` to mirror upstream's method shape even though the body no
      // longer awaits -- the divergence below sources the snapshot synchronously
      // from the live document instead of `await fetchResponse.responseHTML`.
      frame.delegate.fetchResponseLoaded = async (fetchResponse) => {
        if (frame.src) {
          const { statusCode, redirected } = fetchResponse;
          // Divergence from upstream: capture the live, fully rendered page
          // rather than `await fetchResponse.responseHTML`.
          const responseHTML = frame.ownerDocument.documentElement.outerHTML;
          const response = { statusCode, redirected, responseHTML };
          const options = {
            response,
            visitCachedSnapshot,
            willRender: false,
            updateHistory: false,
            restorationIdentifier: this.restorationIdentifier,
            snapshot: pageSnapshot,
          };

          if (this.action) options.action = this.action;

          Turbo.session.visit(frame.src, options);
        }
      };
    }
  };
}
