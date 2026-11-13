export type AttributeDisplay = 'label' | 'value' | 'both';

export const ATTRIBUTE_DISPLAYS:AttributeDisplay[] = ['label', 'value', 'both'];

export const DEFAULT_ATTRIBUTE_DISPLAY:AttributeDisplay = 'value';

export function normalizeDisplay(display:string | undefined):AttributeDisplay {
  return display === 'label' || display === 'both' ? display : DEFAULT_ATTRIBUTE_DISPLAY;
}
