import { createReactBlockSpec } from "@blocknote/react";
import { BlockWorkPackageComponent } from "./BlockWorkPackage";
import { blockConfig } from "./blockConfig";
import {
  computeWorkPackageBlockExternalData,
  parseWorkPackageBlockExternalHTML,
} from "./externalHtml";

export { blockConfig };

export const openProjectWorkPackageBlockSpec = createReactBlockSpec(
  blockConfig,
  {
    render: (props) => (
      <BlockWorkPackageComponent
        block={props.block}
        editor={props.editor as any}
      />
    ),

    toExternalHTML: ({ block }) => {
      const data = computeWorkPackageBlockExternalData(block.props);
      if (!data) return <></>;
      return <div {...data.attrs}>{data.text}</div>;
    },

    parse: (element) => parseWorkPackageBlockExternalHTML(element),
  }
);
