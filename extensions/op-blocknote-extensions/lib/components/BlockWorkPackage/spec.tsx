import { createReactBlockSpec } from '@blocknote/react';
import { BlockWorkPackageComponent } from './BlockWorkPackage';
import { blockConfig } from './blockConfig';
import {
  computeWorkPackageBlockExternalData,
  parseWorkPackageBlockExternalHTML,
} from './externalHtml';
import { PasteWorkPackageLinkExtension } from '../../plugins/pasteWorkPackageLinkExtension';

export { blockConfig };

export const openProjectWorkPackageBlockSpec = createReactBlockSpec(
  blockConfig,
  {
    render: (props) => (
      <BlockWorkPackageComponent
        block={props.block}
        // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-assignment
        editor={props.editor as any}
      />
    ),

    // Produces the same HTML as buildWorkPackageBlockExternalDOM (used by staticSpec.ts).
    // Uses JSX because React's toExternalHTML must return a React element, not a DOM node.
    toExternalHTML: ({ block }) => {
      const data = computeWorkPackageBlockExternalData(block.props);
      if (!data) return <></>;
      return <div {...data.attrs}><a href={data.href}>{data.text}</a></div>;
    },

    parse: (element) => parseWorkPackageBlockExternalHTML(element),
  },

  [
    PasteWorkPackageLinkExtension,
  ]
);
