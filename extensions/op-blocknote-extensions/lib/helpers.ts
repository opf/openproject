import { dummySlashMenu } from "./DummyComponent"
import { openProjectWorkPackageSlashMenu } from "./OpenProjectWorkPackageBlock";

export function getDefaultOpenProjectSlashMenuItems(editor: any): any[] {
  return [
    openProjectWorkPackageSlashMenu(editor),
    dummySlashMenu(editor),
  ];
}