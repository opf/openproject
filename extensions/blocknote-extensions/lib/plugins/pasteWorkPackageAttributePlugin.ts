import { Plugin, PluginKey, type Transaction } from 'prosemirror-state';
import type { Fragment, Node } from 'prosemirror-model';
import type { AnyEditor } from '../editorTypes';
import { findAttributeMacros, type AttributeMacro } from '../components/WorkPackageAttribute/macros';
import { referenceKey, resolveReference, type ResolvedReference } from '../components/WorkPackageAttribute/resolveMacro';
import type { AttributeChoice } from '../components/WorkPackageAttribute/types';
import { BLOCK_WP_ATTRIBUTE_TYPE, INLINE_WP_ATTRIBUTE_TYPE } from '../utils/nodeTypes';

export interface PastedRange { from:number; to:number }

interface MacroOccurrence { macro:AttributeMacro; from:number; to:number }

export const pasteWorkPackageAttributePluginKey = new PluginKey<PastedRange | null>('pasteWorkPackageAttribute');

/**
 * Turns attribute macros pasted from CKEditor (`workPackageValue:58:assignee`)
 * into work package attributes. The paste lands as text, and its macros turn
 * into attributes in place once their work packages have loaded. Macros that
 * cannot be resolved stay text.
 */
export function pasteWorkPackageAttributePlugin(editor:AnyEditor):Plugin<PastedRange | null> {
  return new Plugin<PastedRange | null>({
    key: pasteWorkPackageAttributePluginKey,

    state: {
      init: () => null,
      apply: (tr, pasted) => {
        if (tr.getMeta('uiEvent') === 'paste') return changedRange(tr);
        // Transactions appended to the paste give the pasted blocks their ids.
        if (pasted && tr.getMeta('appendedTransaction')) {
          return { from: tr.mapping.map(pasted.from), to: tr.mapping.map(pasted.to) };
        }
        return null;
      },
    },

    view: () => ({
      update(view, previousState) {
        const pasted = pasteWorkPackageAttributePluginKey.getState(view.state);
        if (!pasted || pasted === pasteWorkPackageAttributePluginKey.getState(previousState)) return;

        const blockIds = blocksWithMacros(view.state.doc, pasted);
        if (blockIds.size > 0) void convertMacros(editor, blockIds);
      },
    }),
  });
}

function changedRange(tr:Transaction):PastedRange | null {
  let from = Infinity;
  let to = -Infinity;
  tr.mapping.maps.forEach((map, index) => {
    const later = tr.mapping.slice(index + 1);
    map.forEach((_oldStart, _oldEnd, newStart, newEnd) => {
      from = Math.min(from, later.map(newStart, -1));
      to = Math.max(to, later.map(newEnd, 1));
    });
  });
  return from <= to ? { from, to } : null;
}

function isMacroHost(node:Node):boolean {
  return node.isTextblock && !node.type.spec.code;
}

// Table cells have no id of their own, so the macros in tables are left alone.
function blockIdOf(container:Node | null):string | undefined {
  const id = container?.attrs.id as unknown;
  return typeof id === 'string' ? id : undefined;
}

function blocksWithMacros(doc:Node, { from, to }:PastedRange):Set<string> {
  const ids = new Set<string>();
  doc.nodesBetween(from, to, (node, _position, container) => {
    if (!isMacroHost(node)) return true;
    const id = blockIdOf(container);
    if (id && findAttributeMacros(node.textContent).length > 0) ids.add(id);
    return false;
  });
  return ids;
}

// Positions do not survive collaboration updates, which replace the whole
// document, so the pasted blocks are looked up again by their ids.
function macrosInBlocks(doc:Node, blockIds:Set<string>):MacroOccurrence[] {
  const occurrences:MacroOccurrence[] = [];
  doc.descendants((node, position, container) => {
    if (!isMacroHost(node)) return true;
    const id = blockIdOf(container);
    if (!id || !blockIds.has(id)) return false;

    node.forEach((child, offset) => {
      for (const macro of findAttributeMacros(child.text ?? '')) {
        const from = position + 1 + offset + macro.start;
        occurrences.push({ macro, from, to: from + macro.end - macro.start });
      }
    });
    return false;
  });
  return occurrences;
}

async function convertMacros(editor:AnyEditor, blockIds:Set<string>):Promise<void> {
  const resolving = new Map<string, Promise<ResolvedReference | null>>();
  for (const { macro } of macrosInBlocks(editor.prosemirrorState.doc, blockIds)) {
    const key = referenceKey(macro);
    if (!resolving.has(key)) resolving.set(key, resolveReference(macro));
  }
  const resolved = new Map(await Promise.all(
    [...resolving].map(async ([key, reference]) => [key, await reference] as const)
  ));

  editor.transact((tr) => {
    // Backwards, so that each replacement leaves the positions before it intact.
    for (const { macro, from, to } of macrosInBlocks(tr.doc, blockIds).reverse()) {
      const reference = resolved.get(referenceKey(macro));
      if (!reference) continue;

      const { kind, ...props } = reference;
      const choice:AttributeChoice = { ...props, display: macro.display };
      if (kind === 'block') replaceWithBlock(tr, from, to, choice);
      else replaceWithInline(tr, from, to, choice);
    }
  });
}

function replaceWithInline(tr:Transaction, from:number, to:number, choice:AttributeChoice):void {
  const type = tr.doc.type.schema.nodes[INLINE_WP_ATTRIBUTE_TYPE];
  if (type) tr.replaceWith(from, to, type.create(choice));
}

// A long text cannot sit inside a line, so the line is split around it.
// Splitting keeps the positions of the text around it, and with them the caret.
function replaceWithBlock(tr:Transaction, from:number, to:number, choice:AttributeChoice):void {
  const $from = tr.doc.resolve(from);
  const line = $from.parent;
  const container = $from.node(-1);
  const typesAfter = [
    { type: container.type, attrs: { ...container.attrs, id: null } },
    { type: line.type, attrs: line.attrs },
  ];

  if (!isBlank(line.content.cut($from.parentOffset + to - from))) tr.split(to, 2, typesAfter);

  let start = from;
  if (!isBlank(line.content.cut(0, $from.parentOffset))) {
    const stepsBefore = tr.steps.length;
    tr.split(from, 2, typesAfter);
    start = tr.mapping.slice(stepsBefore).map(from);
  }

  const $start = tr.doc.resolve(start);
  tr.replaceWith($start.before(), $start.after(), tr.doc.type.schema.nodes[BLOCK_WP_ATTRIBUTE_TYPE].create(choice));
}

// Inline nodes count as content, through their object replacement character.
function isBlank(fragment:Fragment):boolean {
  return fragment.textBetween(0, fragment.size, '', '\ufffc').trim() === '';
}
