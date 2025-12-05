import i18n from "../services/i18n.ts";

let aliases: Array<string> | undefined;

export function getAliases(): string[] {
  return aliases ?? (aliases = calculateAliases());
}

i18n.on('languageChanged', () => {
  aliases = undefined;
});

function calculateAliases(): string[] {
  const combinations: string[] = [];

  for (const namespace of namespaces()) {
    for (const objectType of objectTypes()) {
      for (const functionName of functionNames()) {
        combinations.push(`${namespace} ${objectType} ${functionName}`);
        combinations.push(`${namespace} ${functionName} ${objectType}`);
        combinations.push(`${objectType} ${namespace} ${functionName}`);
        combinations.push(`${objectType} ${functionName} ${namespace}`);
        combinations.push(`${functionName} ${namespace} ${objectType}`);
        combinations.push(`${functionName} ${objectType} ${namespace}`);
      }
    }
  }

  return combinations;
}

function namespaces() {
  return ["openproject", "op"];
}

function objectTypes() {
  const types = new Set<string>();
  types.add("wp");
  types.add("work package");
  types.add("workpackage");
  types.add(i18n.t("slashMenu.aliases.workpackage"));
  types.add(i18n.t("slashMenu.aliases.work package"));
  types.add(i18n.t("slashMenu.aliases.wp"));

  return types;
}

function functionNames() {
  const names = new Set<string>;
  names.add("link");
  names.add(i18n.t("slashMenu.aliases.link"));

  return names;
}