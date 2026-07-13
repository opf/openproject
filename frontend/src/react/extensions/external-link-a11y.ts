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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { createExtension } from '@blocknote/core';
import { Plugin, PluginKey } from 'prosemirror-state';
import { Decoration, DecorationSet } from 'prosemirror-view';
import {
  AddMarkStep,
  RemoveMarkStep,
  ReplaceStep,
  ReplaceAroundStep,
} from 'prosemirror-transform';
import type { Step } from 'prosemirror-transform';
import type { Node as PmNode, Mark, Slice } from 'prosemirror-model';
import { isHrefExternal } from 'core-stimulus/helpers/external-link-helpers';

// ProseMirror primer
// ------------------
// • Transaction (`tr`): an immutable description of an edit. Editor state
//   moves forward by applying transactions, not by direct DOM mutation.
// • Step: the atomic operation a transaction is built from. Relevant ones
//   are ReplaceStep (replace a range with a Slice of content) and
//   AddMarkStep / RemoveMarkStep (toggle a mark like `link` on a range).
// • Slice: the chunk of content carried by a ReplaceStep — what is being
//   pasted, typed, or otherwise inserted.
// • Mapping (`tr.mapping`): ProseMirror's position translator. After an
//   insert of N characters at position 10, mapping rewrites later
//   positions to account for the shift. Decorations can be mapped through
//   it to stay in sync without being rebuilt.
// • Decoration / DecorationSet: non-mutating overlays (widgets, attrs)
//   rendered alongside the document. The sr-only hint here is a widget
//   decoration — invisible to the model, visible (audible) in the DOM.

const pluginKey = new PluginKey('externalLinkA11y');
const DESCRIPTION_ID = 'open-blank-target-link-description';

// --- Decoration construction ------------------------------------------------

function findExternalLinkMark(node:PmNode):Mark|null {
  for (const mark of node.marks) {
    if (mark.type.name === 'link' && isHrefExternal(String(mark.attrs.href ?? ''))) {
      return mark;
    }
  }
  return null;
}

// Detects whether the next inline node belongs to the same contiguous link
// run. Assumes every inline node inside a link carries the link mark. This
// holds for the current BlockNote schema, which has no inline custom nodes
// that opt out of marks. If a mention/inline-embed node is ever added that
// permits a link mark to wrap it without inheriting, revisit this — you will
// need to walk link runs explicitly instead of relying on nodeAfter.
function sameLinkContinues(next:PmNode|null|undefined, href:string):boolean {
  if (!next) return false;
  return next.marks.some(
    (m) => m.type.name === 'link' && String(m.attrs.href ?? '') === href,
  );
}

let missingDescriptionWarned = false;

function readDescription():string {
  const source = document.getElementById(DESCRIPTION_ID);
  const text = source?.textContent?.trim() ?? '';
  if (!text && !missingDescriptionWarned) {
    missingDescriptionWarned = true;
    // The sr-only span is rendered in base.html.erb and also referenced by
    // ExternalLinksController. If it goes missing, external-link hints silently
    // become empty — warn once so the regression surfaces during development.
    console.warn(
      `[ExternalLinkA11yExtension] #${DESCRIPTION_ID} not found; external-link hints will be empty.`,
    );
  }
  return text;
}

function buildWidget():HTMLElement {
  const span = document.createElement('span');
  span.className = 'sr-only';
  // contenteditable=false keeps the hint inert inside ProseMirror's editable
  // region, so users cannot place their caret inside it or delete it.
  span.setAttribute('contenteditable', 'false');
  // Reuse the same translated string the body-level ExternalLinksController
  // references via aria-describedby, keeping i18n centralised in Rails.
  // Captured at decoration-creation time, so a mid-session locale change
  // keeps stale text until the next rebuild. Leading NBSP is a separator
  // for the link's computed accessible name — without it, AT can announce
  // "Link textOpen link in a new tab" because descendant text-node
  // concatenation isn't guaranteed to insert whitespace, especially in
  // contenteditable.
  span.textContent = `\u00A0${readDescription()}`;
  return span;
}

function buildDecorations(doc:PmNode):DecorationSet {
  const decorations:Decoration[] = [];

  doc.descendants((node, pos) => {
    const linkMark = findExternalLinkMark(node);
    if (!linkMark) return;

    const href = String(linkMark.attrs.href ?? '');
    const end = pos + node.nodeSize;
    const next = doc.resolve(end).nodeAfter;

    // Only emit the hint at the end of a contiguous link run. Adjacent inline
    // nodes (e.g. text with an extra bold mark) carrying the same href are
    // rendered as one <a>, so we emit a single hint per link, not per node.
    if (sameLinkContinues(next, href)) return;

    decorations.push(
      Decoration.widget(end, buildWidget, {
        // Wrap the widget in the link mark so the sr-only span is rendered
        // INSIDE the <a> tag. This makes the hint part of the link's
        // accessible name — the only approach that is reliably announced by
        // VoiceOver/NVDA in a contenteditable context, where aria-describedby
        // is widely ignored.
        marks: [linkMark],
        // Negative side keeps the widget attached to the preceding link run
        // when content is inserted at the same position.
        side: -1,
        ignoreSelection: true,
      }),
    );
  });

  return DecorationSet.create(doc, decorations);
}

// --- Transaction gating -----------------------------------------------------

function sliceContainsLinkMark(slice:Slice):boolean {
  let found = false;
  slice.content.descendants((node) => {
    if (found) return false;
    if (node.marks.some((m) => m.type.name === 'link')) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

/**
 * Decides whether a step warrants rebuilding the widget set, vs. just
 * shifting existing decorations forward.
 *
 * Pure typing inserts content without touching link boundaries; the widget
 * at the end of each run rides along correctly via decoration mapping, so
 * the doc walk can be skipped. A rebuild is needed when:
 *   - a link mark is added, removed, or moved by a mark step;
 *   - an inserted slice itself carries a link mark (paste of linked HTML);
 *   - any range is deleted or replaced. Deletions whose right edge meets a
 *     link's trailing widget make `WidgetType.map` report the widget as
 *     deleted (PM's mapping forces `side=1` at the deletion's right edge,
 *     which clashes with our `assoc=-1`). The simplest robust answer is to
 *     reseat the widget set whenever a range is removed.
 */
function stepAffectsLinks(step:Step):boolean {
  if (step instanceof AddMarkStep || step instanceof RemoveMarkStep) {
    return step.mark.type.name === 'link';
  }
  if (step instanceof ReplaceStep || step instanceof ReplaceAroundStep) {
    if (step.from !== step.to) return true;
    return sliceContainsLinkMark(step.slice);
  }
  return false;
}

/**
 * BlockNote extension that adds a screen-reader-only "opens in new tab" hint
 * to external links inside the editor.
 *
 * The hint is injected as a ProseMirror widget decoration wrapped in the link
 * mark, so the resulting DOM looks like:
 *
 *   <a href="..." target="_blank" rel="...">
 *     Link text
 *     <span class="sr-only" contenteditable="false">Open link in a new tab</span>
 *   </a>
 *
 * Putting the text inside the anchor makes it part of the link's accessible
 * name, which screen readers announce in every mode — including the edit mode
 * they switch into inside contenteditable regions. The previous approach of
 * using `aria-describedby` on an inline decoration span did not work in
 * contenteditable: VoiceOver and NVDA ignore aria-describedby there, and the
 * inline decoration landed the attribute on a generic span rather than the
 * anchor anyway.
 *
 * Decorations never mutate the document model, so ProseMirror does not
 * re-render and there is no DOMObserver mutation loop (the reason direct DOM
 * rewriting was abandoned for this attribute).
 */
export const ExternalLinkA11yExtension = createExtension({
  key: 'externalLinkA11y',

  prosemirrorPlugins: [
    new Plugin({
      key: pluginKey,
      state: {
        init(_, { doc }) {
          return buildDecorations(doc);
        },
        // `apply` runs once per transaction to advance plugin state and is
        // the hot path during typing. Three branches:
        //   1. Doc unchanged: decorations are still valid as-is.
        //   2. Doc changed but no step affects link runs: shift existing
        //      decorations forward through the transaction's position
        //      mapping. O(decoration count); no doc walk.
        //   3. A step adds, removes, or moves a link mark: rebuild.
        //
        // The rebuild lives here in `apply` rather than in `appendTransaction`
        // because dispatching a chained meta-only tx from there interferes
        // with y-prosemirror's PM↔Y.Doc sync — paste content gets applied
        // locally but never reaches the rendered view.
        apply(tr, oldDecos) {
          if (!tr.docChanged) return oldDecos;
          if (tr.steps.some(stepAffectsLinks)) return buildDecorations(tr.doc);
          return oldDecos.map(tr.mapping, tr.doc);
        },
      },
      props: {
        decorations(state) {
          return pluginKey.getState(state) as DecorationSet;
        },
      },
    }),
  ],
});
