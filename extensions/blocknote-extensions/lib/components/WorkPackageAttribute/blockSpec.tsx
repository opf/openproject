import { createReactBlockSpec } from '@blocknote/react';
import { attributeBlockConfig } from './blockConfig';
import { WorkPackageAttributeBlock } from './WorkPackageAttributeBlock';
import { attributePropsOf } from './types';
import {
  computeWorkPackageAttributeExternalData,
  parseWorkPackageAttributeExternalHTML,
} from './externalHtml';

export const openProjectWorkPackageAttributeBlockSpec = createReactBlockSpec(
  attributeBlockConfig,
  {
    render: ({ block, editor }) => (
      <WorkPackageAttributeBlock
        blockId={block.id}
        content={attributePropsOf(block.props)}
        editor={editor}
        onDisplayChange={(display) => editor.updateBlock(block, { props: { display } })}
      />
    ),

    toExternalHTML: ({ block }) => {
      const data = computeWorkPackageAttributeExternalData(block.props, 'block');
      if (!data) return <></>;
      return <div {...data.attrs}><p>{data.text}</p></div>;
    },

    parse: (element) => parseWorkPackageAttributeExternalHTML(element, 'block'),
  }
);
