#!/usr/bin/env node
// Regenerates config/frontend_assets.manifest.json from the compiled assets in
// public/assets/frontend/. Run after `npm run build` to keep the manifest in sync.
// Mirrors the logic in lib/open_project/assets.rb#rebuild_manifest!

const fs = require('fs');
const path = require('path');

const frontendPath = path.resolve(__dirname, '../public/assets/frontend');
const manifestPath = path.resolve(__dirname, '../config/frontend_assets.manifest.json');

// Mirrors Ruby's split_basename: strips the hash suffix and returns [unhashedName, ext]
// e.g. "styles-IXSKP5UD.css"  -> ["styles", ".css"]
//      "foo.component-AB12CD34.css.map" -> ["foo.component", ".css.map"]
const HASHED_NAME_RE = /^([^.]+)[-.]([A-Z0-9]{8})$/;

function splitBasename(file) {
  if (file.endsWith('.css.map')) {
    return [file.slice(0, -'.css.map'.length), '.css.map'];
  }
  if (file.endsWith('.js.map')) {
    return [file.slice(0, -'.js.map'.length), '.js.map'];
  }
  const dot = file.lastIndexOf('.');
  if (dot === -1) return [file, ''];
  return [file.slice(0, dot), file.slice(dot)];
}

function walkDir(dir, base) {
  const results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...walkDir(full, base));
    } else {
      results.push(path.relative(base, full).replace(/\\/g, '/'));
    }
  }
  return results;
}

const manifest = {};

for (const relpath of walkDir(frontendPath, frontendPath)) {
  const basename = path.basename(relpath);
  const dir = path.dirname(relpath);
  const prefix = dir === '.' ? '' : dir + '/';

  const [name, ext] = splitBasename(basename);
  const m = name.match(HASHED_NAME_RE);
  if (!m) continue;

  const unhashedName = m[1];

  if (unhashedName === 'chunk') {
    manifest[relpath] = relpath;
  } else {
    manifest[prefix + unhashedName + ext] = relpath;
    manifest[relpath] = relpath;
  }
}

fs.writeFileSync(manifestPath, JSON.stringify(manifest));
console.log(`Manifest written to ${manifestPath} (${Object.keys(manifest).length} entries)`);
