import {OpTableAction} from 'core-components/wp-table/table-actions/table-action';
import {opIconElement} from 'core-app/helpers/op-icon-builder';
import {
  contextColumnIcon,
  contextMenuLinkClassName
} from 'core-components/wp-fast-table/builders/table-action-renderer';


export class OpContextMenuTableAction extends OpTableAction {

  public readonly identifier = 'open-context-menu-action';

  private text = {
    linkTitle: this.I18n.t('js.label_open_context_menu')
  };

  public buildElement() {
    let contextMenu = document.createElement('a');
    contextMenu.href = '#';
    contextMenu.classList.add(contextMenuLinkClassName, contextColumnIcon);
    contextMenu.title = this.text.linkTitle;
    contextMenu.appendChild(opIconElement('icon', 'icon-show-more-horizontal'));

    return contextMenu;
  }
}
