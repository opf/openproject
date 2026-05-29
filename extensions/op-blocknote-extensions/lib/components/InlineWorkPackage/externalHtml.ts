// Single source of truth for the HTML that both browser-side copy-to-clipboard
// and server-side markdown export emit for an openProjectWorkPackageInline.
//
// Mirrors the structure of BlockWorkPackage/externalHtml.ts so that the React
// spec and the static spec produce byte-identical output.

import { buildExternalDOM, hashPrefixForSize } from '../WorkPackage/externalHtml';
import { linkToWorkPackage } from '../../services/openProjectApi';

export interface WorkPackageInlineProps {
  wpid?:string;
  instanceId?:string;
  size?:string;
  displayId?:string;
}

export interface WorkPackageInlineExternalData {
  attrs:{
    'data-inline-content-type':'openProjectWorkPackageInline';
    'data-wpid':string;
    'data-instance-id':string;
    'data-size':string;
    'data-display-id':string;
  };
  text:string;
  href:string;
}

export function computeWorkPackageInlineExternalData(
  props:WorkPackageInlineProps,
):WorkPackageInlineExternalData | null {
  const { wpid, instanceId, size } = props;
  if (!wpid || wpid.startsWith('pending:')) return null;
  // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
  const displayId = props.displayId || wpid;
  return {
    attrs: {
      'data-inline-content-type': 'openProjectWorkPackageInline',
      'data-wpid': wpid,
      'data-instance-id': instanceId ?? '',
      'data-size': size ?? 's',
      'data-display-id': displayId,
    },
    text: hashPrefixForSize(size) + displayId,
    href: linkToWorkPackage(wpid),
  };
}

export function buildWorkPackageInlineExternalDOM(
  data:WorkPackageInlineExternalData,
  doc:Document,
):HTMLElement {
  return buildExternalDOM('span', data.attrs, data.text, doc, data.href);
}

export function parseWorkPackageInlineExternalHTML(
  element:HTMLElement,
):WorkPackageInlineProps | undefined {
  if (element.getAttribute('data-inline-content-type') !== 'openProjectWorkPackageInline') {
    return undefined;
  }
  return {
    wpid: element.getAttribute('data-wpid') ?? '',
    instanceId: element.getAttribute('data-instance-id') ?? '',
    size: element.getAttribute('data-size') ?? 's',
    displayId: element.getAttribute('data-display-id') ?? '',
  };
}
