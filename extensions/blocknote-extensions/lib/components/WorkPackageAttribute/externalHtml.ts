// Shared by copy-to-clipboard and the server-side markdown export. The text
// is the same attribute macro OpenProject renders for work package
// attributes inserted with CKEditor.

import { BLOCK_ATTRIBUTE_TYPE, INLINE_ATTRIBUTE_TYPE } from '../../utils/nodeTypes';

export type AttributeDisplay = 'label' | 'value' | 'both';

export interface WorkPackageAttributeProps {
  wpid?:string;
  displayId?:string;
  attribute?:string;
  display?:string;
}

// Long text attributes are blocks, everything else sits inline. A block wraps
// its macro in a paragraph, so the markdown export keeps it apart from its
// neighbours while the paragraph parser leaves the block itself alone.
export type AttributeNodeKind = 'inline' | 'block';

const NODES = {
  inline: { tag: 'span', marker: 'data-inline-content-type', type: INLINE_ATTRIBUTE_TYPE },
  block: { tag: 'div', marker: 'data-block-content-type', type: BLOCK_ATTRIBUTE_TYPE },
} as const;

export interface WorkPackageAttributeExternalData {
  tag:'span' | 'div';
  attrs:Record<string, string>;
  text:string;
}

export function normalizeDisplay(display:string | undefined):AttributeDisplay {
  return display === 'label' || display === 'both' ? display : 'value';
}

// The macro syntax only accepts these characters inside quotes.
function macroId(id:string):string {
  return /[\s:"]/.test(id) ? `"${id}"` : id;
}

export function attributeMacro(
  kind:'Label' | 'Value',
  reference:string,
  attribute:string,
):string {
  return `workPackage${kind}:${macroId(reference)}:"${attribute}"`;
}

export function computeWorkPackageAttributeExternalData(
  props:WorkPackageAttributeProps,
  kind:AttributeNodeKind = 'inline',
):WorkPackageAttributeExternalData | null {
  const { wpid, attribute } = props;
  if (!wpid || wpid.startsWith('pending:') || !attribute) return null;
  // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
  const displayId = props.displayId || wpid;
  const display = normalizeDisplay(props.display);
  const label = attributeMacro('Label', displayId, attribute);
  const value = attributeMacro('Value', displayId, attribute);
  const text = display === 'label' ? label : display === 'value' ? value : `${label}: ${value}`;
  const node = NODES[kind];
  return {
    tag: node.tag,
    attrs: {
      [node.marker]: node.type,
      'data-wpid': wpid,
      'data-display-id': displayId,
      'data-attribute': attribute,
      'data-display': display,
    },
    text,
  };
}

export function buildWorkPackageAttributeExternalDOM(
  data:WorkPackageAttributeExternalData,
  doc:Document,
):HTMLElement {
  const element = doc.createElement(data.tag);
  for (const [name, value] of Object.entries(data.attrs)) {
    element.setAttribute(name, value);
  }
  if (data.tag === 'div') {
    element.appendChild(doc.createElement('p')).textContent = data.text;
  } else {
    element.textContent = data.text;
  }
  return element;
}

export function parseWorkPackageAttributeExternalHTML(
  element:HTMLElement,
  kind:AttributeNodeKind = 'inline',
):WorkPackageAttributeProps | undefined {
  const node = NODES[kind];
  if (element.getAttribute(node.marker) !== node.type) return undefined;
  return {
    wpid: element.getAttribute('data-wpid') ?? '',
    displayId: element.getAttribute('data-display-id') ?? '',
    attribute: element.getAttribute('data-attribute') ?? '',
    display: normalizeDisplay(element.getAttribute('data-display') ?? undefined),
  };
}
