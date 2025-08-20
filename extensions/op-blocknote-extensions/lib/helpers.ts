import {
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageSlashMenu
} from "./OpenProjectWorkPackageBlock";

export function getDefaultOpenProjectSlashMenuItems(editor: any): any[] {
  return [
    openProjectWorkPackageSlashMenu(editor),
  ];
}

export function getDefaultOpenProjectBlockSpecs(): any[] {
  return [
    openProjectWorkPackageBlockSpec,
  ];
}
