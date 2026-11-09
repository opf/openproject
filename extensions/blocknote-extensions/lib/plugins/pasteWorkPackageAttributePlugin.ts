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

        const hostKeys = hostsWithMacros(view.state.doc, pasted);
        if (hostKeys.size > 0) void convertMacros(editor, hostKeys);
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

interface MacroHost { key:string; node:Node; position:number }

function isMacroHost(node:Node):boolean {
  return node.isTextblock && !node.type.spec.code;
}

function blockIdOf(node:Node):string | undefined {
  const id = node.attrs.id as unknown;
  return typeof id === 'string' ? id : undefined;
}

// Positions do not survive collaboration updates, which replace the whole
// document, so a line is known by its block and its place in it: a table
// cell has no id of its own.
function forEachMacroHost(doc:Node, visit:(host:MacroHost) => void):void {
  doc.descendants((node, position) => {
    const id = blockIdOf(node);
    const content = node.firstChild;
    if (!id || !content) return true;

    const contentStart = position + 1;
    if (isMacroHost(content)) {
      visit({ key: `${id}:0`, node: content, position: contentStart });
      return true;
    }

    let line = 0;
    content.descendants((child, offset) => {
      if (!isMacroHost(child)) return true;
      visit({ key: `${id}:${line}`, node: child, position: contentStart + 1 + offset });
      line += 1;
      return false;
    });
    return true;
  });
}

function hostsWithMacros(doc:Node, { from, to }:PastedRange):Set<string> {
  const keys = new Set<string>();
  forEachMacroHost(doc, ({ key, node, position }) => {
    const overlaps = position < to && position + node.nodeSize > from;
    if (overlaps && findAttributeMacros(node.textContent).length > 0) keys.add(key);
  });
  return keys;
}

function macrosInHosts(doc:Node, keys:Set<string>):MacroOccurrence[] {
  const occurrences:MacroOccurrence[] = [];
  forEachMacroHost(doc, ({ key, node, position }) => {
    if (!keys.has(key)) return;
    node.forEach((child, offset) => {
      for (const macro of findAttributeMacros(child.text ?? '')) {
        const from = position + 1 + offset + macro.start;
        occurrences.push({ macro, from, to: from + macro.end - macro.start });
      }
    });
  });
  return occurrences;
}

async function convertMacros(editor:AnyEditor, hostKeys:Set<string>):Promise<void> {
  const resolving = new Map<string, Promise<ResolvedReference | null>>();
  for (const { macro } of macrosInHosts(editor.prosemirrorState.doc, hostKeys)) {
    const key = referenceKey(macro);
    if (!resolving.has(key)) resolving.set(key, resolveReference(macro));
  }
  const resolved = new Map(await Promise.all(
    [...resolving].map(async ([key, reference]) => [key, await reference] as const)
  ));

  editor.transact((tr) => {
    // Backwards, so that each replacement leaves the positions before it intact.
    for (const { macro, from, to } of macrosInHosts(tr.doc, hostKeys).reverse()) {
      const reference = resolved.get(referenceKey(macro));
      if (!reference) continue;

      const { kind, ...props } = reference;
      const choice:AttributeChoice = { ...props, display: macro.display };
      if (kind === 'inline') replaceWithInline(tr, from, to, choice);
      else if (canHoldBlock(tr, from)) replaceWithBlock(tr, from, to, choice);
    }
  });
}

function replaceWithInline(tr:Transaction, from:number, to:number, choice:AttributeChoice):void {
  const type = tr.doc.type.schema.nodes[INLINE_WP_ATTRIBUTE_TYPE];
  if (type) tr.replaceWith(from, to, type.create(choice));
}

function canHoldBlock(tr:Transaction, position:number):boolean {
  return blockIdOf(tr.doc.resolve(position).node(-1)) !== undefined;
}

// A long text cannot sit inside a line, so the line is split around it.
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
