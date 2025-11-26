import {describe, it, expect} from "vitest";
import {openProjectWorkPackageSlashMenu} from "../../../lib/components/OpenProjectWorkPackageBlock";

describe("openProjectWorkPackageSlashMenu", () => {
  it("calculates all possible aliases for the slash menu", () => {
    const slashMenu = openProjectWorkPackageSlashMenu({} as any);
    const actual = slashMenu.aliases
    const expected = [
      "openproject work package link", "openproject workpackage link", "openproject wp link",
      "op work package link", "op workpackage link", "op wp link",
      "openproject link work package", "openproject link workpackage", "openproject link wp",
      "op link work package", "op link workpackage", "op link wp",
      "work package openproject link", "work package op link",
      "workpackage openproject link", "workpackage op link",
      "wp openproject link", "wp op link",
      "work package link openproject", "work package link op",
      "workpackage link openproject", "workpackage link op",
      "wp link openproject", "wp link op",
      "link work package openproject", "link work package op",
      "link workpackage openproject", "link workpackage op",
      "link wp openproject", "link wp op",
      "link openproject work package", "link openproject workpackage", "link openproject wp",
      "link op work package", "link op workpackage", "link op wp"
    ]
    expect(actual.sort()).toEqual(expected.sort());
  });
});