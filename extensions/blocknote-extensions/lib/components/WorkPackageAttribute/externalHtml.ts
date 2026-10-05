// Shared by copy-to-clipboard and the server-side markdown export. The text
// is the same attribute macro OpenProject renders for work package
// attributes inserted with CKEditor.

export type AttributeDisplay = 'label' | 'value' | 'both';

export interface WorkPackageAttributeProps {
  wpid?:string;
  displayId?:string;
  attribute?:string;
  display?:string;
}

export interface WorkPackageAttributeExternalData {
  attrs:{
    'data-inline-content-type':'openProjectWorkPackageAttribute';
    'data-wpid':string;
    'data-display-id':string;
    'data-attribute':string;
    'data-display':AttributeDisplay;
  };
  text:string;
}

export function normalizeDisplay(display:string | undefined):AttributeDisplay {
  return display === 'label' || display === 'both' ? display : 'value';
}

// The macro syntax only accepts these characters inside quotes.
function macroSegment(segment:string):string {
  return /[\s:."]/.test(segment) ? `"${segment}"` : segment;
}

export function attributeMacro(
  kind:'Label' | 'Value',
  reference:string,
  attribute:string,
):string {
  return `workPackage${kind}:${macroSegment(reference)}:${macroSegment(attribute)}`;
}

export function computeWorkPackageAttributeExternalData(
  props:WorkPackageAttributeProps,
):WorkPackageAttributeExternalData | null {
  const { wpid, attribute } = props;
  if (!wpid || wpid.startsWith('pending:') || !attribute) return null;
  // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
  const displayId = props.displayId || wpid;
  const display = normalizeDisplay(props.display);
  const label = attributeMacro('Label', displayId, attribute);
  const value = attributeMacro('Value', displayId, attribute);
  const text = display === 'label' ? label : display === 'value' ? value : `${label}: ${value}`;
  return {
    attrs: {
      'data-inline-content-type': 'openProjectWorkPackageAttribute',
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
  const element = doc.createElement('span');
  for (const [name, value] of Object.entries(data.attrs)) {
    element.setAttribute(name, value);
  }
  element.textContent = data.text;
  return element;
}

export function parseWorkPackageAttributeExternalHTML(
  element:HTMLElement,
):WorkPackageAttributeProps | undefined {
  if (element.getAttribute('data-inline-content-type') !== 'openProjectWorkPackageAttribute') {
    return undefined;
  }
  return {
    wpid: element.getAttribute('data-wpid') ?? '',
    displayId: element.getAttribute('data-display-id') ?? '',
    attribute: element.getAttribute('data-attribute') ?? '',
    display: normalizeDisplay(element.getAttribute('data-display') ?? undefined),
  };
}
