import { WorkPackageAction } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';

export const PERMITTED_CONTEXT_MENU_ACTIONS:WorkPackageAction[] = [
  {
    key: 'log_time',
    link: 'logTime',
  },
  {
    key: 'change_project',
    icon: 'icon-move',
    link: 'move',
  },
  {
    key: 'copy',
    link: 'copy',
  },
  {
    key: 'copy_link_to_clipboard',
    icon: 'icon-clipboard',
    link: 'id',
  },
  {
    key: 'copy_to_other_project',
    link: 'copy',
    icon: 'icon-project-types',
  },
  {
    key: 'delete',
    link: 'delete',
  },
  {
    key: 'export-pdf',
    link: 'pdf',
  },
  {
    key: 'export-atom',
    link: 'atom',
  },
];
