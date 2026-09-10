#!/bin/bash
# Public runtime distribution; source remains in private basedagent/kief-skool.
# Requires Node >=22.12 and npm, but no GitHub account or gh for students.
# Install the generic versioned release:
# curl -fsSL https://raw.githubusercontent.com/basedagent/kief-skool-downloads/main/install.sh | /bin/bash
# The immutable bootstrap alternative uses the public v0.3.0 tag instead of main.
# To download manually:
# gh release download v0.3.0 --repo basedagent/kief-skool-downloads --pattern 'kief-skool-0.3.0.tar.gz' --pattern SHA256SUMS
# /bin/bash scripts/install.sh --version 0.3.0 --archive /absolute/kief-skool-0.3.0.tar.gz --checksums /absolute/SHA256SUMS
# Local overrides require BOTH files and the same checksum verification as releases.
set -euo pipefail
command -v node >/dev/null 2>&1 || { echo 'Install Node.js >=22.12 with npm from https://nodejs.org/en/download, then run this command again. Kief Skool does not require sudo.' >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { echo 'npm is required. Install it with Node.js before retrying.' >&2; exit 1; }
node --input-type=module - "$@" <<'NODE'
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { createHash, randomUUID } from 'node:crypto';
import { gunzipSync } from 'node:zlib';
import { spawnSync } from 'node:child_process';

function fail(message) { throw new Error(message); }
function run(command, args, cwd) {
  const result = spawnSync(command, args, { cwd, stdio: 'inherit' });
  if (result.error || result.status !== 0) fail(`${command} failed: ${result.error?.message || result.status || result.signal}`);
}
function exists(file) { try { return fs.lstatSync(file); } catch (error) { if (error.code === 'ENOENT') return null; throw error; } }
async function download(url, file, maxBytes) {
  const response = await fetch(url, { signal: AbortSignal.timeout(120_000) });
  if (!response.ok) fail(`Download failed (${response.status}): ${url}. The version may not be published yet.`);
  const chunks = []; let size = 0;
  for await (const chunk of response.body) {
    size += chunk.length;
    if (size > maxBytes) fail('Release download exceeds its size limit.');
    chunks.push(chunk);
  }
  fs.writeFileSync(file, Buffer.concat(chunks), { mode: 0o600, flag: 'wx' });
}
const [major, minor] = process.versions.node.split('.').map(Number);
if (major < 22 || (major === 22 && minor < 12)) { console.error(`Node.js >=22.12 required; found ${process.version}.`); process.exit(1); }
console.log(`System: ${os.platform()} ${os.arch()}${os.platform() === 'darwin' && os.arch() === 'arm64' ? ' (Apple Silicon)' : ''}; Node ${process.version}.`);
let stage, lock, temp, nextLink, nextLauncher, switched = false, previous = null, current, destination, newVersion = false;
try {
  const args = process.argv.slice(2), opts = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--help') { console.log('install.sh [--version X.Y.Z] [--archive FILE --checksums FILE]\nRequires Node >=22.12 and npm. Downloads public versioned releases; no account needed.'); process.exit(0); }
    const key = args[i];
    if (!['--version', '--archive', '--checksums'].includes(key) || opts[key] || !args[i + 1] || args[i + 1].startsWith('--')) fail(`Invalid installer option: ${key}`);
    opts[key] = args[++i];
  }
  const version = opts['--version'] || '0.3.0';
  if (!/^\d+\.\d+\.\d+$/.test(version)) fail('Version must be X.Y.Z.');
  if (Boolean(opts['--archive']) !== Boolean(opts['--checksums'])) fail('--archive and --checksums must be supplied together.');
  if (process.getuid?.() === 0) fail('Do not run the installer as root or with sudo.');
  const home = fs.realpathSync(os.homedir());
  const base = path.join(home, '.local/share/kief-skool');
  const bin = path.join(home, '.local/bin');
  const launcher = path.join(bin, 'kief-skool');
  const expectedLauncher = path.join(base, 'current/bin/kief-skool');
  for (const relative of ['.local', '.local/share', '.local/bin', '.local/share/kief-skool']) {
    const dir = path.join(home, relative);
    if (!exists(dir)) fs.mkdirSync(dir, { mode: 0o700 });
    const entry = fs.lstatSync(dir);
    if (!entry.isDirectory() || entry.isSymbolicLink() || entry.uid !== process.getuid?.()) fail(`Unsafe or non-user-owned installation directory: ${dir}`);
  }
  const marker = path.join(base, '.kief-skool-install.json');
  if (exists(marker)) {
    const value = JSON.parse(fs.readFileSync(marker, 'utf8'));
    if (value.product !== 'kief-skool' || value.schemaVersion !== 1) fail('Unrecognized existing installation.');
  } else if (fs.readdirSync(base).length) fail('Installation directory is not empty and is not managed by Kief Skool.');
  if (exists(launcher) && (!fs.lstatSync(launcher).isSymbolicLink() || fs.readlinkSync(launcher) !== expectedLauncher)) fail(`Refusing to overwrite unrelated launcher: ${launcher}`);
  const lockPath = path.join(base, '.install-lock');
  try { fs.mkdirSync(lockPath, { mode: 0o700 }); lock = lockPath; } catch { fail('Another installation/uninstall is running. If interrupted, inspect and remove the .install-lock directory before retrying.'); }
  const versions = path.join(base, 'versions');
  if (!exists(versions)) fs.mkdirSync(versions, { mode: 0o700 });
  const versionsStat = fs.lstatSync(versions);
  if (!versionsStat.isDirectory() || versionsStat.isSymbolicLink() || versionsStat.uid !== process.getuid?.()) fail('Unsafe versions directory.');
  current = path.join(base, 'current');
  if (exists(current)) {
    if (!fs.lstatSync(current).isSymbolicLink()) fail('Current installation must be a managed symlink.');
    previous = fs.readlinkSync(current);
    if (!/^versions\/\d+\.\d+\.\d+$/.test(previous)) fail('Current symlink is not a managed version.');
    console.log(`Existing installation: ${previous.slice(9)}. Upgrading to ${version}; previous version retained.`);
  }
  destination = path.join(versions, version);
  if (exists(destination)) fail(`Version ${version} is already present. No changes made. Install a newer version instead.`);
  // Keep the marker even after failure so a fresh install can safely be retried.
  if (!exists(marker)) fs.writeFileSync(marker, JSON.stringify({ product: 'kief-skool', schemaVersion: 1 }) + '\n', { mode: 0o600, flag: 'wx' });
  temp = fs.mkdtempSync(path.join(os.tmpdir(), 'kief-skool-download-'));
  const filename = `kief-skool-${version}.tar.gz`;
  let archive, checksums;
  if (opts['--archive']) {
    archive = path.resolve(opts['--archive']); checksums = path.resolve(opts['--checksums']);
  } else {
    console.log(`Downloading public Kief Skool v${version} (no account required).`);
    archive = path.join(temp, filename); checksums = path.join(temp, 'SHA256SUMS');
    const baseUrl = `https://github.com/basedagent/kief-skool-downloads/releases/download/v${version}`;
    await download(`${baseUrl}/SHA256SUMS`, checksums, 1024 * 1024);
    await download(`${baseUrl}/${filename}`, archive, 128 * 1024 * 1024);
  }
  const lines = fs.readFileSync(checksums, 'utf8').split(/\r?\n/).map(line => /^([a-fA-F0-9]{64})\s+\*?(.+)$/.exec(line)).filter(match => match?.[2] === filename);
  if (lines.length !== 1) fail(`SHA256SUMS must contain exactly one checksum for ${filename}.`);
  if (fs.statSync(archive).size > 128 * 1024 * 1024) fail('Release archive exceeds 128 MiB limit.');
  const compressed = fs.readFileSync(archive);
  if (createHash('sha256').update(compressed).digest('hex') !== lines[0][1].toLowerCase()) fail('SHA256 verification failed. Existing installation unchanged.');
  console.log('SHA256 verified. Staging installation.');
  stage = fs.mkdtempSync(path.join(versions, `.stage-${version}-`));
  // Our release script emits portable USTAR only. Reject links, devices, PAX and
  // traversal before writing each entry; extraction never invokes archive code.
  const tar = gunzipSync(compressed, { maxOutputLength: 256 * 1024 * 1024 });
  const names = new Set();
  const field = (header, start, length) => header.subarray(start, start + length).toString('utf8').split('\0')[0];
  const octal = value => { if (!/^[0-7]+$/.test(value.trim())) fail('Invalid archive number.'); return parseInt(value.trim(), 8); };
  let ended = false;
  for (let offset = 0; offset + 512 <= tar.length;) {
    const header = tar.subarray(offset, offset + 512);
    if (header.every(byte => byte === 0)) { ended = true; break; }
    const expected = octal(field(header, 148, 8));
    let sum = 0;
    for (let i = 0; i < 512; i++) sum += i >= 148 && i < 156 ? 32 : header[i];
    if (sum !== expected || field(header, 257, 5) !== 'ustar') fail('Invalid USTAR archive.');
    const prefix = field(header, 345, 155);
    const name = `${prefix ? prefix + '/' : ''}${field(header, 0, 100)}`.replace(/\/$/, '');
    const type = field(header, 156, 1);
    const size = octal(field(header, 124, 12));
    if (name.includes('\\') || name.split('/').some(part => !part || part === '.' || part === '..') || names.has(name)) fail('Unsafe or duplicate archive path.');
    if (!['0', '', '5'].includes(type)) fail('Archive links and special entries are not allowed.');
    if (type === '5' && size !== 0) fail('Invalid archive directory.');
    if (!Number.isSafeInteger(size) || offset + 512 + size > tar.length) fail('Truncated archive.');
    names.add(name);
    const top = `kief-skool-${version}`;
    if (name !== top && !name.startsWith(top + '/')) fail('Archive has an unexpected root directory.');
    const relative = name.slice(top.length + 1);
    if (!relative && type !== '5') fail('Archive root must be a directory.');
    if (relative) {
      if (!/^(dist|bin|server|scripts)(\/|$)/.test(relative) && !['package.json', 'package-lock.json', 'server.mjs'].includes(relative)) fail(`Unexpected release file: ${relative}`);
      if (relative.split('/').some(part => part.startsWith('.') || ['course-materials', 'data', 'public', 'node_modules'].includes(part))) fail(`Disallowed release file: ${relative}`);
      const output = path.join(stage, relative);
      if (type === '5') fs.mkdirSync(output, { recursive: true, mode: 0o755 });
      else {
        fs.mkdirSync(path.dirname(output), { recursive: true, mode: 0o755 });
        fs.writeFileSync(output, tar.subarray(offset + 512, offset + 512 + size), { flag: 'wx', mode: relative === 'bin/kief-skool' || relative === 'scripts/install.sh' ? 0o755 : 0o644 });
      }
    }
    offset += 512 + Math.ceil(size / 512) * 512;
  }
  if (!ended) fail('Archive is missing its end marker.');
  const pkg = JSON.parse(fs.readFileSync(path.join(stage, 'package.json'), 'utf8'));
  if (pkg.name !== 'kief-skool' || pkg.version !== version) fail('Release package name/version mismatch.');
  for (const file of ['package-lock.json', 'server.mjs', 'server/store.mjs', 'dist/index.html', 'bin/kief-skool', 'bin/kief-skool.mjs', 'scripts/install.sh']) {
    if (!fs.statSync(path.join(stage, file)).isFile()) fail(`Missing release file: ${file}`);
  }
  run('npm', ['ci', '--omit=dev', '--ignore-scripts', '--no-audit', '--no-fund'], stage);
  run(process.execPath, [path.join(stage, 'bin/kief-skool.mjs'), '--version'], stage);
  fs.renameSync(stage, destination); stage = null; newVersion = true;
  nextLink = path.join(base, `.current-${randomUUID()}`);
  fs.symlinkSync(`versions/${version}`, nextLink);
  nextLauncher = path.join(bin, `.kief-skool-${randomUUID()}`);
  fs.symlinkSync(expectedLauncher, nextLauncher);
  fs.renameSync(nextLink, current); nextLink = null; switched = true;
  fs.renameSync(nextLauncher, launcher); nextLauncher = null;
  console.log(`Installed Kief Skool ${version}.\nRun: "${launcher}" start --open\nAdd "$HOME/.local/bin" to PATH if needed. No shell profile was changed.\nStudent data is separate and was not modified. Restart a running app to use this version.`);
} catch (error) {
  if (switched) {
    try {
      if (previous) { const rollback = `${current}.rollback-${randomUUID()}`; fs.symlinkSync(previous, rollback); fs.renameSync(rollback, current); }
      else fs.rmSync(current, { force: true });
      switched = false;
    } catch (rollbackError) { console.error(`Rollback needs attention: ${rollbackError.message}`); }
  }
  if (newVersion && !switched) fs.rmSync(destination, { recursive: true, force: true });
  console.error(`Installation failed: ${error.message}`);
  process.exitCode = 1;
} finally {
  for (const file of [nextLink, nextLauncher]) if (file) fs.rmSync(file, { force: true });
  for (const dir of [stage, temp]) if (dir) fs.rmSync(dir, { recursive: true, force: true });
  if (lock) fs.rmdirSync(lock);
}
NODE
