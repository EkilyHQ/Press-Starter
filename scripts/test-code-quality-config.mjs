import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { evaluateBaselineTransition, evaluateBootstrapBaseline } from './format-baseline-policy.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const EXPECTED_DEV_DEPENDENCIES = {
  '@eslint/js': '10.0.1',
  eslint: '10.6.0',
  globals: '17.7.0',
  prettier: '3.9.4'
};
const EXPECTED_FORMAT_EXCLUDED_FILES = [
  '.nojekyll',
  'README.md',
  'index.html',
  'index_editor.html',
  'index_editor_preview.html',
  'press-system-lock.json',
  'site.yaml'
];
const EXPECTED_FORMAT_EXCLUDED_PREFIXES = ['assets/', 'dist/', 'node_modules/', 'wwwroot/'];

function read(relativePath) {
  return fs.readFileSync(path.join(ROOT, relativePath), 'utf8');
}

function readJson(relativePath) {
  return JSON.parse(read(relativePath));
}

function countMatches(source, pattern) {
  return [...source.matchAll(pattern)].length;
}

const packageJson = readJson('package.json');
assert.equal(packageJson.private, true, 'the YAP development-only quality package must remain private');
assert.equal(packageJson.type, undefined, 'the package must not reinterpret existing CommonJS .js scripts');
assert.deepEqual(packageJson.engines, { node: '>=22.18.0 <23' }, 'quality tooling must stay on the CI Node line');
assert.equal(packageJson.packageManager, 'npm@10.9.3', 'the lockfile owner must remain pinned');
assert.deepEqual(packageJson.devDependencies, EXPECTED_DEV_DEPENDENCIES, 'quality dependencies must stay minimal');
for (const version of Object.values(packageJson.devDependencies)) {
  assert.match(version, /^\d+\.\d+\.\d+$/u, 'quality dependency versions must be exact');
}
assert.equal(packageJson.scripts?.lint, 'eslint "scripts/**/*.{js,mjs}" --max-warnings 0');
assert.equal(packageJson.scripts?.['lint:debt-probe'], 'node scripts/probe-eslint-debt.mjs');
assert.equal(packageJson.scripts?.['lint:policy-test'], 'node scripts/test-eslint-policy.mjs');
assert.equal(packageJson.scripts?.['format:check'], 'node scripts/check-format.mjs');
assert.equal(
  packageJson.scripts?.quality,
  'node scripts/test-code-quality-config.mjs && npm run lint:policy-test && npm run lint && npm run lint:debt-probe && npm run format:check'
);

const packageLock = readJson('package-lock.json');
assert.equal(packageLock.lockfileVersion, 3, 'npm 10 must own a lockfile v3 dependency graph');
assert.equal(packageLock.packages?.['']?.name, packageJson.name);
assert.deepEqual(packageLock.packages?.['']?.engines, packageJson.engines);
assert.deepEqual(packageLock.packages?.['']?.devDependencies, EXPECTED_DEV_DEPENDENCIES);

const gitignore = read('.gitignore');
assert.match(gitignore, /^node_modules\/$/mu, 'node_modules must remain ignored');
const editorConfig = read('.editorconfig');
assert.match(editorConfig, /^root = true$/mu);
assert.match(editorConfig, /^end_of_line = lf$/mu);
assert.match(editorConfig, /^insert_final_newline = true$/mu);
assert.match(editorConfig, /^indent_size = 2$/mu);
assert.deepEqual(readJson('.prettierrc.json'), {
  printWidth: 120,
  singleQuote: true,
  semi: true,
  trailingComma: 'none'
});

const eslintConfig = read('eslint.config.mjs');
assert.match(eslintConfig, /js\.configs\.recommended\.rules/u, 'all recommended rules must stay enabled');
assert.match(eslintConfig, /noInlineConfig:\s*true/u, 'inline lint configuration must be forbidden');
assert.match(eslintConfig, /reportUnusedDisableDirectives:\s*'error'/u);
assert.match(eslintConfig, /files:\s*\['scripts\/\*\*\/\*\.js'\]/u);
assert.match(eslintConfig, /files:\s*\['scripts\/\*\*\/\*\.mjs'\]/u);
assert.match(eslintConfig, /sourceType:\s*'commonjs'/u, 'existing .js tooling must remain CommonJS');
assert.match(eslintConfig, /sourceType:\s*'module'/u, '.mjs tooling must remain modules');
for (const ignoredPath of ['assets/**', 'dist/**', 'node_modules/**', 'wwwroot/**']) {
  assert.ok(eslintConfig.includes(`'${ignoredPath}'`), `ESLint must ignore ${ignoredPath}`);
}
assert.deepEqual(
  [...eslintConfig.matchAll(/['"]([^'"]+)['"]\s*:\s*['"]off['"]/gu)].map((match) => match[1]),
  [],
  'YAP tooling must not disable recommended rules'
);
assert.equal(
  fs.existsSync(path.join(ROOT, 'eslint-suppressions.json')),
  false,
  'bulk ESLint suppressions are forbidden'
);

const policy = readJson('scripts/code-quality-policy.json');
assert.equal(policy.schemaVersion, 1);
assert.equal(policy.eslint?.profile, '@eslint/js recommended');
assert.deepEqual(policy.eslint?.scope, ['scripts/**/*.js', 'scripts/**/*.mjs']);
assert.deepEqual(policy.eslint?.baseline, {
  decision: 'enforced-zero-baseline',
  observedDiagnostics: 0,
  excludedRules: [],
  probeCommand: 'node scripts/probe-eslint-debt.mjs'
});
assert.deepEqual(policy.eslint?.inlineConfiguration, {
  decision: 'forbidden',
  mechanism: 'linterOptions.noInlineConfig',
  regressionCommand: 'node scripts/test-eslint-policy.mjs',
  policy:
    'Source comments cannot disable or reconfigure lint rules; a directive beside a real no-undef violation must leave that violation unsuppressed.'
});
assert.equal(policy.eslint?.noGrowth?.mechanism, 'zero-baseline');
assert.equal(policy.eslint?.noGrowth?.command, packageJson.scripts.lint);
assert.equal(policy.prettier?.baseline?.file, 'scripts/prettier-baseline.json');
assert.equal(policy.prettier?.baseline?.initialFiles, 4);
assert.match(policy.prettier?.baseline?.observedAtCommit, /^[0-9a-f]{40}$/u);
assert.deepEqual(policy.prettier?.excludedFiles, EXPECTED_FORMAT_EXCLUDED_FILES);
assert.deepEqual(policy.prettier?.excludedPrefixes, EXPECTED_FORMAT_EXCLUDED_PREFIXES);
assert.equal(policy.prettier?.noGrowth?.mechanism, 'merge-base-shrinking-file-baseline');
assert.equal(policy.prettier?.noGrowth?.baseRefEnvironmentVariable, 'CODE_QUALITY_BASE_REF');
assert.equal(policy.prettier?.noGrowth?.headShaEnvironmentVariable, 'CODE_QUALITY_HEAD_SHA');

const prettierBaseline = readJson('scripts/prettier-baseline.json');
assert.equal(prettierBaseline.schemaVersion, 1);
assert.equal(prettierBaseline.files.length, policy.prettier.baseline.initialFiles);
assert.deepEqual(prettierBaseline.files, [...new Set(prettierBaseline.files)].sort());
for (const file of prettierBaseline.files) {
  assert.match(file, /^scripts\/.*\.(?:js|json|mjs|yaml|yml)$/u, `${file} must stay in YAP-owned tooling`);
}
for (const excludedPath of EXPECTED_FORMAT_EXCLUDED_FILES) {
  assert.equal(prettierBaseline.files.includes(excludedPath), false, `${excludedPath} must stay outside format policy`);
}
for (const excludedPrefix of EXPECTED_FORMAT_EXCLUDED_PREFIXES) {
  assert.equal(
    prettierBaseline.files.some((file) => file.startsWith(excludedPrefix)),
    false,
    `${excludedPrefix} must stay outside format policy`
  );
}

assert.deepEqual(
  evaluateBaselineTransition({
    baseFiles: ['legacy.js'],
    headFiles: ['legacy.js'],
    changes: [{ status: 'M', oldPath: 'legacy.js', newPath: 'legacy.js' }]
  }),
  [{ code: 'touched-baseline-retained', file: 'legacy.js' }]
);
assert.deepEqual(
  evaluateBaselineTransition({
    baseFiles: ['legacy.js'],
    headFiles: ['renamed.js'],
    changes: [{ status: 'R100', oldPath: 'legacy.js', newPath: 'renamed.js' }]
  }),
  []
);
assert.deepEqual(evaluateBaselineTransition({ baseFiles: [], headFiles: ['new.js'], changes: [] }), [
  { code: 'baseline-growth', file: 'new.js' }
]);
assert.deepEqual(evaluateBootstrapBaseline({ basePaths: ['legacy.js'], headFiles: ['new.js'], changes: [] }), [
  { code: 'bootstrap-path-not-in-base', file: 'new.js' }
]);
assert.deepEqual(
  evaluateBootstrapBaseline({
    basePaths: ['legacy.js'],
    headFiles: ['legacy.js'],
    changes: [{ status: 'M', oldPath: 'legacy.js', newPath: 'legacy.js' }]
  }),
  [{ code: 'bootstrap-touched-baseline-retained', file: 'legacy.js' }]
);
assert.deepEqual(evaluateBootstrapBaseline({ basePaths: ['legacy.js'], headFiles: ['legacy.js'], changes: [] }), []);

const formatCheck = read('scripts/check-format.mjs');
assert.match(formatCheck, /gitText\(\['merge-base', baseTip, head\]\)/u);
assert.match(formatCheck, /CODE_QUALITY_HEAD_SHA/u);
assert.match(formatCheck, /--find-renames=100%/u);
assert.match(formatCheck, /evaluateBootstrapBaseline/u);
for (const excludedPath of EXPECTED_FORMAT_EXCLUDED_FILES) {
  assert.ok(formatCheck.includes(`'${excludedPath}'`), `format guard must exclude ${excludedPath}`);
}
for (const excludedPrefix of EXPECTED_FORMAT_EXCLUDED_PREFIXES) {
  assert.ok(formatCheck.includes(`'${excludedPrefix}'`), `format guard must exclude ${excludedPrefix}`);
}

const eslintDebtProbe = read('scripts/probe-eslint-debt.mjs');
assert.match(eslintDebtProbe, /scripts\/\*\*\/\*\.js/u);
assert.match(eslintDebtProbe, /scripts\/\*\*\/\*\.mjs/u);
assert.match(eslintDebtProbe, /diagnostics\.length > 0/u);
const eslintPolicyTest = read('scripts/test-eslint-policy.mjs');
assert.match(eslintPolicyTest, /eslint-disable-next-line no-undef/u);
assert.match(eslintPolicyTest, /message\.ruleId === 'no-undef'/u);
assert.match(eslintPolicyTest, /result\.errorCount > 0/u);

const workflow = read('.github/workflows/code-quality.yml');
assert.match(workflow, /^name: Code Quality$/mu);
assert.match(workflow, /^ {2}push:\n {4}branches:\n {6}- main$/mu);
assert.match(workflow, /^ {2}pull_request:\n {4}branches:\n {6}- main$/mu);
assert.match(workflow, /^ {2}workflow_dispatch:$/mu);
assert.match(workflow, /^ {2}schedule:\n {4}- cron: '[^']+ [^']+ \* \* [0-6]'$/mu);
assert.match(workflow, /^permissions:\n {2}contents: read$/mu);
assert.doesNotMatch(workflow, /(?:write-all|contents:\s*write)/u);
assert.match(workflow, /^concurrency:\n {2}group: code-quality-/mu);
assert.match(workflow, /uses: actions\/checkout@v6/u);
assert.match(workflow, /fetch-depth: 0/u);
assert.match(workflow, /persist-credentials: false/u);
assert.match(workflow, /ref: \$\{\{ github\.event\.pull_request\.head\.sha \|\| github\.sha \}\}/u);
assert.match(workflow, /uses: actions\/setup-node@v6/u);
assert.match(workflow, /node-version: 22\.18\.0/u);
assert.match(workflow, /run: npm ci --ignore-scripts/u);
assert.match(workflow, /run: npm run quality/u);
assert.match(
  workflow,
  /CODE_QUALITY_BASE_REF: \$\{\{ github\.event\.pull_request\.base\.sha \|\| github\.event\.before \|\| github\.sha \}\}/u
);
assert.match(workflow, /CODE_QUALITY_HEAD_SHA: \$\{\{ github\.event\.pull_request\.head\.sha \|\| github\.sha \}\}/u);
assert.match(workflow, /git merge-base "\$CODE_QUALITY_BASE_REF" "\$CODE_QUALITY_HEAD_SHA"/u);
assert.match(workflow, /git diff --check "\$quality_base_sha" "\$CODE_QUALITY_HEAD_SHA"/u);
assert.equal(countMatches(workflow, /git status --porcelain --untracked-files=all/gu), 3);
assert.match(workflow, /- name: Verify quality gate cleanup\n {8}if: always\(\)/u);

process.stdout.write('Code-quality configuration self-test passed.\n');
