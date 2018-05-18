import {InsertMode} from '../wp-attachments-formattable.enums';
import IAugmentedJQuery = angular.IAugmentedJQuery;

export class MarkupModel {
  public createMarkup(insertUrl:string, insertMode:InsertMode, addLineBreak:boolean = false):string {
    if (angular.isUndefined((insertUrl))) {
      return '';
    }

    var markup:string = ' ';

    switch (insertMode) {
      case InsertMode.ATTACHMENT:
        markup += 'attachment:' + insertUrl.split('/').pop();
        break;
      case InsertMode.DELAYED_ATTACHMENT:
        markup += 'attachment:' + insertUrl;
        break;
      case InsertMode.INLINE:
        markup += '!' + insertUrl + '!';
        break;
      case InsertMode.LINK:
        markup += insertUrl;
        break;
    }

    if (addLineBreak) {
      markup += '\r\n';
    }

    return markup;
  }
}
