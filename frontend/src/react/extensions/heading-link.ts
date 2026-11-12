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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { createExtension } from '@blocknote/core';
import type { Node as ProsemirrorNode } from 'prosemirror-model';
import { Plugin, PluginKey } from 'prosemirror-state';
import { AddMarkStep, RemoveMarkStep, ReplaceStep } from 'prosemirror-transform';
import type { Step } from 'prosemirror-transform';
import { Decoration, DecorationSet } from 'prosemirror-view';
import type { EditorView } from 'prosemirror-view';
import { alertIconData, checkIconData, linkIconData, toDOMString } from '@openproject/octicons-angular';

const ANCHOR_PREFIX = 'heading-';
const BLOCK_CONTAINER = '[data-node-type="blockContainer"]';
const HEADING = '[data-content-type="heading"]';
const COLLAPSED_TOGGLE_BUTTON = ':scope > .bn-block-content .bn-toggle-wrapper[data-show-children="false"] > .bn-toggle-button';
const USER_INPUT_EVENTS = ['pointerdown', 'keydown', 'wheel', 'touchstart'] as const;
const FEEDBACK_DURATION = 2000;
const TAP_MOVE_TOLERANCE = 10;
const GHOST_CLICK_WINDOW = 700;

const ICONS = {
  copy: linkIconData,
  copied: checkIconData,
  failed: alertIconData,
};

type ButtonState = keyof typeof ICONS;

function blockIdFromHash(hash:string):string|null {
  const anchor = hash.slice(1);
  return anchor.startsWith(ANCHOR_PREFIX) ? anchor.slice(ANCHOR_PREFIX.length) : null;
}

function headingUrl(blockId:string):string {
  const url = new URL(window.location.href);
  url.hash = `${ANCHOR_PREFIX}${blockId}`;
  return url.href;
}

// iOS Safari holds the click of a first tap back until a second one, so a tap
// activates from touchend and the click that may still follow is ignored.
function onActivate(element:HTMLElement, activate:() => void) {
  let tapStart:{ x:number, y:number }|null = null;
  let tappedAt = Number.NEGATIVE_INFINITY;

  element.addEventListener('touchstart', (event) => {
    const touch = event.changedTouches[0];
    tapStart = touch ? { x: touch.clientX, y: touch.clientY } : null;
  }, { passive: true });

  element.addEventListener('touchend', (event) => {
    const start = tapStart;
    const touch = event.changedTouches[0];
    tapStart = null;
    if (!start || !touch) return;
    if (Math.hypot(touch.clientX - start.x, touch.clientY - start.y) > TAP_MOVE_TOLERANCE) return;

    event.preventDefault();
    tappedAt = event.timeStamp;
    activate();
  });

  element.addEventListener('click', (event) => {
    if (event.timeStamp - tappedAt < GHOST_CLICK_WINDOW) return;
    activate();
  });
}

function createHeadingLinkButton(blockId:string):HTMLButtonElement {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'op-heading-link';
  button.contentEditable = 'false';
  button.tabIndex = -1;
  // Inside the heading, a label would become part of the heading's name.
  button.setAttribute('aria-hidden', 'true');

  const url = () => headingUrl(blockId);
  const titles:Record<ButtonState, () => string> = {
    copy: () => I18n.t('js.button_copy_link_to_clipboard'),
    copied: () => I18n.t('js.clipboard.copied_successful'),
    failed: () => I18n.t('js.clipboard.browser_error', { content: url() }),
  };

  const showState = (state:ButtonState) => {
    button.title = titles[state]();
    button.dataset.state = state;
    button.innerHTML = toDOMString(ICONS[state], 'small', { fill: 'currentColor' });
  };
  showState('copy');

  let resetTimer:number|undefined;
  const showFeedback = (state:ButtonState) => {
    showState(state);
    window.clearTimeout(resetTimer);
    resetTimer = window.setTimeout(() => showState('copy'), FEEDBACK_DURATION);
  };

  const copyLink = async () => {
    try {
      await navigator.clipboard.writeText(url());
      showFeedback('copied');
    } catch {
      showFeedback('failed');
    }
  };

  // Keeps the browser from moving the caret or focus into the heading.
  button.addEventListener('mousedown', (event) => event.preventDefault());
  onActivate(button, () => { void copyLink(); });

  return button;
}

const isHeading = (node:ProsemirrorNode) => node.type.name === 'heading';

function buildDecorations(doc:ProsemirrorNode):DecorationSet {
  const decorations:Decoration[] = [];

  doc.descendants((node, pos) => {
    const content = node.firstChild;
    const blockId = String(node.attrs.id ?? '');
    if (node.type.name === 'blockContainer' && content && isHeading(content) && content.content.size > 0 && blockId) {
      const headingStart = pos + 1;
      const headingContentEnd = headingStart + content.nodeSize - 1;
      decorations.push(
        Decoration.widget(headingContentEnd, () => createHeadingLinkButton(blockId), {
          key: `heading-link-${blockId}`,
          side: 1,
          ignoreSelection: true,
          stopEvent: () => true,
        }),
      );
    }
    // Headings can be nested in other blocks' children, but never inside text.
    return !node.isTextblock;
  });

  return DecorationSet.create(doc, decorations);
}

function stepAffectsHeadings(step:Step, doc:ProsemirrorNode):boolean {
  if (step instanceof AddMarkStep || step instanceof RemoveMarkStep) return false;
  if (!(step instanceof ReplaceStep)) return true;

  let found = false;
  const findHeading = (node:ProsemirrorNode) => {
    found ||= isHeading(node);
    return !found;
  };
  doc.nodesBetween(step.from, step.to, findHeading);
  step.slice.content.descendants(findHeading);
  return found;
}

// Through its own button, so BlockNote also remembers the toggle as open.
function openCollapsedToggles(heading:Element) {
  let block = heading.closest(BLOCK_CONTAINER)?.parentElement?.closest(BLOCK_CONTAINER);
  while (block) {
    block.querySelector<HTMLButtonElement>(COLLAPSED_TOGGLE_BUTTON)?.click();
    block = block.parentElement?.closest(BLOCK_CONTAINER);
  }
}

// The browser cannot reach into the shadow root, and content above the heading keeps loading.
function followAnchor(view:EditorView) {
  let targetId:string|null = null;

  const scrollToTarget = () => {
    if (!targetId) return;
    const heading = view.dom.querySelector(`[data-id="${CSS.escape(targetId)}"] > ${HEADING}`);
    if (!heading) return;

    openCollapsedToggles(heading);
    heading.scrollIntoView({ block: 'start' });
  };

  const follow = () => {
    targetId = blockIdFromHash(window.location.hash);
    scrollToTarget();
  };

  const stopFollowing = () => { targetId = null; };

  const resizeObserver = new ResizeObserver(scrollToTarget);
  resizeObserver.observe(view.dom);
  window.addEventListener('hashchange', follow);
  USER_INPUT_EVENTS.forEach((type) => window.addEventListener(type, stopFollowing, { capture: true, passive: true }));
  follow();

  return {
    update: scrollToTarget,
    destroy: () => {
      resizeObserver.disconnect();
      window.removeEventListener('hashchange', follow);
      USER_INPUT_EVENTS.forEach((type) => window.removeEventListener(type, stopFollowing, { capture: true }));
    },
  };
}

const pluginKey = new PluginKey<DecorationSet>('headingLink');

export const HeadingLinkExtension = createExtension(() => ({
  key: 'headingLink',
  prosemirrorPlugins: [
    new Plugin<DecorationSet>({
      key: pluginKey,
      state: {
        init: (_, state) => buildDecorations(state.doc),
        apply: (transaction, decorations) => {
          if (!transaction.docChanged) return decorations;

          return transaction.steps.some((step, index) => stepAffectsHeadings(step, transaction.docs[index]))
            ? buildDecorations(transaction.doc)
            : decorations.map(transaction.mapping, transaction.doc);
        },
      },
      props: {
        decorations: (state) => pluginKey.getState(state),
      },
      view: followAnchor,
    }),
  ],
}))();
