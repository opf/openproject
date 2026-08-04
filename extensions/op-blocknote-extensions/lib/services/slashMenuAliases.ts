import i18n from '../services/i18n.ts';

export type SlashMenuFunction = 'link' | 'create';

const aliases:Partial<Record<SlashMenuFunction, string[]>> = {};

export function getAliases(functionName:SlashMenuFunction = 'link'):string[] {
  return aliases[functionName] ?? (aliases[functionName] = calculateAliases(functionName));
}

i18n.on('languageChanged', () => {
  delete aliases.link;
  delete aliases.create;
});

function calculateAliases(functionName:SlashMenuFunction):string[] {
  const combinations:string[] = [];

  for (const namespace of namespaces()) {
    for (const objectType of objectTypes()) {
      for (const name of functionNames(functionName)) {
        combinations.push(`${namespace} ${objectType} ${name}`);
        combinations.push(`${namespace} ${name} ${objectType}`);
        combinations.push(`${objectType} ${namespace} ${name}`);
        combinations.push(`${objectType} ${name} ${namespace}`);
        combinations.push(`${name} ${namespace} ${objectType}`);
        combinations.push(`${name} ${objectType} ${namespace}`);
      }
    }
  }

  return combinations;
}

function namespaces() {
  return ['openproject', 'op'];
}

function objectTypes() {
  const types = new Set<string>();
  types.add('wp');
  types.add('work package');
  types.add('workpackage');
  types.add(i18n.t('slashMenu.aliases.workpackage'));
  types.add(i18n.t('slashMenu.aliases.work package'));
  types.add(i18n.t('slashMenu.aliases.wp'));

  return types;
}

function functionNames(functionName:SlashMenuFunction) {
  const names = new Set<string>;
  names.add(functionName);
  names.add(i18n.t(`slashMenu.aliases.${functionName}`));

  return names;
}
