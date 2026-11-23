import { createContext, useContext } from 'react';

const labels = {
  'js.blocknote.file_source': 'File source',
  'js.blocknote.link_url': 'URL',
  'js.blocknote.link_text': 'Link text',
  'js.blocknote.formatting_toolbar': 'Text formatting',
  'js.blocknote.block_type': 'Block type',
  'js.blocknote.cell_actions': 'Cell actions',
  'js.blocknote.extend_rows': 'Extend rows',
  'js.blocknote.extend_columns': 'Extend columns',
  'js.blocknote.row_actions': 'Row actions',
  'js.blocknote.column_actions': 'Column actions',
  'js.label_loading': 'Loading',
  'js.button_close': 'Close',
  'js.button_save': 'Save',
  'js.blocknote.active_format': '%{format} (active)',
};

export type EditorTranslate = (key:keyof typeof labels, options?:{ format:string }) => string;

export const EditorTranslationContext = createContext<EditorTranslate>((key, options) =>
  options ? labels[key].replace('%{format}', () => options.format) : labels[key]);

export function useEditorTranslation() {
  return useContext(EditorTranslationContext);
}
