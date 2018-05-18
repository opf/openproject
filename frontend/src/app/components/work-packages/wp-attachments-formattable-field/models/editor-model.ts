import {IApplyAttachmentMarkup} from '../wp-attachments-formattable.interfaces';
import {InsertMode} from '../wp-attachments-formattable.enums';
import {MarkupModel} from './markup-model';
import IAugmentedJQuery = angular.IAugmentedJQuery;

export class EditorModel implements IApplyAttachmentMarkup {
  private currentCaretPosition:number;
  public contentToInsert:string = '';

  constructor(protected textarea:IAugmentedJQuery, protected markupModel:MarkupModel) {
    this.setCaretPosition();
  }

  public insertWebLink(url:string, insertMode:InsertMode = InsertMode.LINK):void {
    this.contentToInsert = this.markupModel.createMarkup(url, insertMode);
  }

  public insertAttachmentLink(url:string,
                              insertMode:InsertMode = InsertMode.ATTACHMENT,
                              addLineBreak?:boolean):void {
    this.contentToInsert = (addLineBreak) ?
      this.contentToInsert + this.markupModel.createMarkup(url, insertMode, addLineBreak) :
      this.markupModel.createMarkup(url, insertMode, addLineBreak);
  }

  private setCaretPosition():void {
    this.currentCaretPosition = (this.textarea[0] as HTMLTextAreaElement).selectionStart;
  }

  public save():void {
    let insertPosition = this.normalizeInputAndGetInsertPosition();
    let currentValue = this.textarea.val();

    let newValue = currentValue.substring(0, insertPosition) +
      this.contentToInsert +
      currentValue.substring(this.currentCaretPosition, currentValue.length);

    this.textarea.val(newValue).change();
  }

  /*
   * Assure that no whitespace is left before the inlined image as whitespaces will lead to the image being wrapped in a
   * <pre><code>image</code><pre> block
   * Removes two sources of whitespace:
   *  * The whitespace prepended to the content to insert
   *  * Whitespace added by the user on a newline
   */

  private normalizeInputAndGetInsertPosition() {
    let currentValue = this.textarea.val();
    let newlineMatch = currentValue.substring(0, this.currentCaretPosition).match(/\n *$/);
    let newlineIndex = newlineMatch && newlineMatch.index || 0;
    let whitespacesBeforeCaret = this.currentCaretPosition - newlineIndex;

    if (whitespacesBeforeCaret > 0) {
      this.contentToInsert = this.contentToInsert.substring(1, this.contentToInsert.length);
    }

    return (newlineIndex && newlineIndex + 1) || this.currentCaretPosition;
  }
}
