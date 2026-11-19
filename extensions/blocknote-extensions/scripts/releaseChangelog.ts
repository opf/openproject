const SECTIONS = {
  added: 'Added',
  changed: 'Changed',
  deprecated: 'Deprecated',
  removed: 'Removed',
  fixed: 'Fixed',
  security: 'Security',
} as const;

type SectionType = keyof typeof SECTIONS;

export interface Fragment {
  fileName:string;
  content:string;
}

interface Entry {
  name:string;
  section:SectionType;
  text:string;
}

const FRAGMENT_NAME = /^(.+)\.([a-z]+)\.md$/;
const TICKET = /^[A-Z]+-\d+$/;
const FIRST_RELEASE = /^## \[/m;

function isSection(type:string):type is SectionType {
  return Object.keys(SECTIONS).includes(type);
}

function parseFragment({ fileName, content }:Fragment):Entry {
  const [, name, type] = FRAGMENT_NAME.exec(fileName) ?? [];
  if (!name || !isSection(type)) {
    throw new Error(`${fileName}: expected <ticket>.<type>.md, with type one of ${Object.keys(SECTIONS).join(', ')}`);
  }

  const text = content.trim().replace(/^- /, '');
  if (!text || text.includes('\n')) throw new Error(`${fileName}: expected exactly one line`);

  const link = TICKET.test(name) ? ` ([${name}](https://community.openproject.org/wp/${name}))` : '';
  return { name, section: type, text: `${text}${link}` };
}

function renderSection(version:string, entries:Entry[]):string {
  const sorted = [...entries].sort((a, b) => a.name.localeCompare(b.name, 'en', { numeric: true }));
  const sections = (Object.keys(SECTIONS) as SectionType[])
    .map((type) => [SECTIONS[type], sorted.filter((entry) => entry.section === type)] as const)
    .filter(([, inSection]) => inSection.length > 0)
    .map(([title, inSection]) => `### ${title}\n\n${inSection.map((entry) => `- ${entry.text}`).join('\n')}\n`);

  return `## [${version}]\n\n${sections.join('\n')}\n`;
}

export function releaseChangelog(changelog:string, version:string, fragments:Fragment[]):string {
  if (fragments.length === 0) throw new Error('There are no changelog entries to release');
  if (changelog.includes(`## [${version}]`)) {
    throw new Error(`The changelog already has a section for ${version}. Bump the version in package.json first.`);
  }

  const firstRelease = FIRST_RELEASE.exec(changelog);
  if (!firstRelease) throw new Error('The changelog has no release section to add the new one above');

  const section = renderSection(version, fragments.map(parseFragment));
  return changelog.slice(0, firstRelease.index) + section + changelog.slice(firstRelease.index);
}
