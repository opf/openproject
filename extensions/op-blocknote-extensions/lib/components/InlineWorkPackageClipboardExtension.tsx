import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from 'prosemirror-state';
import { DOMSerializer, Slice, Fragment } from 'prosemirror-model';

// Use window as shared storage to avoid issues with duplicate module instances
// (e.g. when the lib is bundled separately from the consumer app).
// OpBlockNoteEditor captures the raw HTML before TipTap clears clipboardData,
// and handlePaste reads it from here.
declare global {
  interface Window {
    __opLastWpPasteHtml?: string | null;
  }
}

export function setLastPasteHtml(html: string): void {
  window.__opLastWpPasteHtml = html;
}

export const InlineWorkPackageClipboardExtension = Extension.create({
  name: 'inlineWorkPackageClipboard',

  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('inlineWorkPackageClipboard'),

        props: {
          // SERIALIZE
          clipboardSerializer: (() => {
            let serializer: DOMSerializer | null = null;

            const getSerializer = (schema: any): DOMSerializer => {
              if (serializer) return serializer;

              const nodes = { ...DOMSerializer.fromSchema(schema).nodes };

              if (schema.nodes.inlineWorkPackage) {
                nodes['inlineWorkPackage'] = (node: any) => {
                  const wpid = node.attrs.wpid;
                  if (!wpid || String(wpid).startsWith('pending:')) {
                    return ['span', {}];
                  }
                  return [
                    'a',
                    {
                      href: `./wp/${wpid}`,
                      'data-inline-wp': String(wpid),
                      target: '_blank',
                      rel: 'noopener noreferrer',
                    },
                    `#${wpid}`,
                  ];
                };
              }

              serializer = new DOMSerializer(
                nodes,
                DOMSerializer.fromSchema(schema).marks,
              );
              return serializer;
            };

            return {
              serializeFragment: (fragment: any, options: any, target: any) => {
                const schema =
                  fragment.firstChild?.type?.schema ??
                  fragment.content?.[0]?.type?.schema;
                const s = schema
                  ? getSerializer(schema)
                  : DOMSerializer.fromSchema(fragment.firstChild?.type?.schema ?? {});
                return s.serializeFragment(fragment, options, target);
              },
            } as unknown as DOMSerializer;
          })(),

          // ── PARSE (paste) ─────────────────────────────────────────────────
          handlePaste(view, _event) {
            const html = window.__opLastWpPasteHtml ?? null;
            window.__opLastWpPasteHtml = null;

            if (!html || !html.includes('data-inline-wp')) return false;

            const schema = view.state.schema;
            const nodeType = schema.nodes['inlineWorkPackage'];
            if (!nodeType) return false;

            const parser = new DOMParser();
            const doc = parser.parseFromString(html, 'text/html');

            const nodes: any[] = [];

            const walk = (el: Node) => {
              if (el.nodeType === Node.TEXT_NODE) {
                const text = el.textContent ?? '';
                if (text) nodes.push(schema.text(text));
                return;
              }
              if (el.nodeType !== Node.ELEMENT_NODE) return;

              const element = el as HTMLElement;
              const wpid = element.getAttribute('data-inline-wp');
              if (wpid) {
                nodes.push(nodeType.create({ wpid }));
                return;
              }
              for (const child of Array.from(element.childNodes)) {
                walk(child);
              }
            };

            for (const child of Array.from(doc.body.childNodes)) {
              walk(child);
            }

            if (nodes.length === 0) return false;

            const paragraphType = schema.nodes['paragraph'];
            let slice: Slice;
            try {
              const fragment = Fragment.from(nodes);
              const wrappedNodes = nodes.every((n) => n.isInline)
                ? [paragraphType.create(null, fragment)]
                : nodes;
              slice = new Slice(Fragment.from(wrappedNodes), 0, 0);
            } catch {
              return false;
            }

            const { tr } = view.state;
            tr.replaceSelection(slice);
            view.dispatch(tr);
            return true;
          },
        },
      }),
    ];
  },
});