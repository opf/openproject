import { readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { releaseChangelog } from './releaseChangelog.ts';

function main() {
  const packageDir = join(import.meta.dirname, '..');
  const changelogPath = join(packageDir, 'CHANGELOG.md');
  const unreleasedDir = join(packageDir, 'changelog', 'unreleased');

  const { version } = JSON.parse(readFileSync(join(packageDir, 'package.json'), 'utf8')) as { version:string };
  const fragmentPaths = readdirSync(unreleasedDir)
    .filter((fileName) => fileName.endsWith('.md'))
    .map((fileName) => ({ fileName, path: join(unreleasedDir, fileName) }));
  const fragments = fragmentPaths.map(({ fileName, path }) => ({ fileName, content: readFileSync(path, 'utf8') }));

  writeFileSync(changelogPath, releaseChangelog(readFileSync(changelogPath, 'utf8'), version, fragments));
  fragmentPaths.forEach(({ path }) => rmSync(path));
  process.stdout.write(`Released ${fragments.length} changelog entries as ${version}\n`);
}

try {
  main();
}
catch (error) {
  process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
  process.exitCode = 1;
}
