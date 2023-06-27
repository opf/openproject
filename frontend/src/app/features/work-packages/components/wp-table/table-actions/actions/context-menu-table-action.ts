import {
  contextColumnIcon,
  contextMenuLinkClassName,
  OpTableAction,
} from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { spotIconElement } from 'core-app/shared/helpers/spot-icon-builder';

export class OpContextMenuTableAction extends OpTableAction {
  public readonly identifier = 'open-context-menu-action';

  private text = {
    linkTitle: this.I18n.t('js.label_open_context_menu'),
  };

  public buildElement() {
    const contextMenu = document.createElement('a');
    contextMenu.href = '#';
    contextMenu.classList.add(contextMenuLinkClassName, contextColumnIcon);
    contextMenu.title = this.text.linkTitle;
    contextMenu.appendChild(spotIconElement('show-more-horizontal'));

    return contextMenu;
  }
}
