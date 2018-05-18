import {InsertMode} from './wp-attachments-formattable.enums';

export interface IApplyAttachmentMarkup {
  contentToInsert:string;

  insertAttachmentLink:(url:string, insertMode:InsertMode, addLineBreak?:boolean) => void;
  insertWebLink:(url:string, insertMode:InsertMode) => void;
  save:() => void;
}
