import {
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageSlashMenu
} from "./components/OpenProjectWorkPackageBlock";

export function getDefaultOpenProjectSlashMenuItems(editor: any): any[] {
  return [
    openProjectWorkPackageSlashMenu(editor),
  ];
}

export const defaultOpenProjectBlockSpecs = {
  "openProjectWorkPackage": openProjectWorkPackageBlockSpec(),
}
