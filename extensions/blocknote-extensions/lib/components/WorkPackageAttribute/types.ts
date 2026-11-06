import type { AttributeDisplay } from './externalHtml';

export interface AttributeProps {
  wpid:string;
  displayId:string;
  attribute:string;
  display:string;
}

export interface AttributeChoice extends AttributeProps {
  display:AttributeDisplay;
}

// The stored displayId may be '' (the schema default), which `??` would keep.
export function attributePropsOf(props:AttributeProps):AttributeProps {
  return { ...props, displayId: props.displayId || props.wpid };
}
