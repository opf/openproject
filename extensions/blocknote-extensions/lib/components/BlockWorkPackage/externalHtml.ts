// Single source of truth for the HTML that both browser-side copy-to-clipboard
// and server-side markdown export emit for an openProjectWorkPackageBlock.
//
// Two surfaces:
// - computeWorkPackageBlockExternalData: pure transformation from block props
//   to the data needed to render external HTML. Used by both spec variants.
// - buildWorkPackageBlockExternalDOM: takes the data and builds an HTMLElement
//   via a provided Document. Used by the static (vanilla) spec.
//
// The React spec applies the same data via JSX so the produced HTML matches
// byte-for-byte.

import { buildExternalDOM, hashPrefixForSize } from '../WorkPackage/externalHtml';
import { linkToWorkPackage } from '../../services/openProjectApi';

export interface WorkPackageBlockProps {
  wpid?:number | string;
  size?:string;
  displayId?:string;
}

export interface WorkPackageBlockExternalData {
  attrs:{
    'data-block-content-type':'openProjectWorkPackageBlock';
    'data-wpid':string;
    'data-size':string;
    'data-display-id':string;
  };
  text:string;
  href:string;
}

export function computeWorkPackageBlockExternalData(
  props:WorkPackageBlockProps,
):WorkPackageBlockExternalData | null {
  const wpid = props.wpid;
  if (!wpid) return null;
  // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
  const displayId = props.displayId || String(wpid);
  return {
    attrs: {
      'data-block-content-type': 'openProjectWorkPackageBlock',
      'data-wpid': String(wpid),
      'data-size': props.size ?? 'm',
      'data-display-id': displayId,
    },
    text: hashPrefixForSize(props.size) + displayId,
    href: linkToWorkPackage(String(wpid)),
  };
}

export function buildWorkPackageBlockExternalDOM(
  data:WorkPackageBlockExternalData,
  doc:Document,
):HTMLElement {
  return buildExternalDOM('div', data.attrs, data.text, doc, data.href);
}

export function parseWorkPackageBlockExternalHTML(
  element:HTMLElement,
):WorkPackageBlockProps | undefined {
  if (element.getAttribute('data-block-content-type') !== 'openProjectWorkPackageBlock') {
    return undefined;
  }
  const wpid = element.getAttribute('data-wpid');
  const size = element.getAttribute('data-size') ?? 'm';
  const displayId = element.getAttribute('data-display-id') ?? '';
  return {
    wpid: wpid ? Number(wpid) : undefined,
    size,
    displayId,
  };
}
