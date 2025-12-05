import {describe, it, expect} from "vitest";
import {openProjectWorkPackageSlashMenu} from "../../../lib/components/OpenProjectWorkPackageBlock";
import {initLanguage} from "../../../lib/services/i18n";


describe("openProjectWorkPackageSlashMenu", () => {
  it("is translated", () => {
    initLanguage("de")
    let slashMenu = openProjectWorkPackageSlashMenu({} as any);
    expect(slashMenu.title).toBe("Vorhandenes Arbeitspaket verlinken");

    initLanguage("en")
    slashMenu = openProjectWorkPackageSlashMenu({} as any);
    expect(slashMenu.title).toBe("Link existing work package");
  });

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

  it("also keeps english object types for aliases in other languages", () => {
    initLanguage("de");
    const slashMenu = openProjectWorkPackageSlashMenu({} as any);
    const actual = slashMenu.aliases

    expect(actual).toContain("openproject work package link");
    expect(actual).toContain("openproject Arbeitspaket link");
    expect(actual).toContain("openproject wp link");
    expect(actual).toContain("openproject ap link");
    initLanguage("en"); // reset for next test
  });
});