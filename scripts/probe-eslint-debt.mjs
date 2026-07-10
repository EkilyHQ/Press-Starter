#!/usr/bin/env node

import { ESLint } from 'eslint';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, '..');

async function main() {
  const eslint = new ESLint({ cwd: REPO_ROOT, errorOnUnmatchedPattern: true });
  const results = await eslint.lintFiles(['scripts/**/*.js', 'scripts/**/*.mjs']);
  const diagnostics = results.flatMap((result) =>
    result.messages.map((message) => ({
      file: path.relative(REPO_ROOT, result.filePath),
      line: message.line,
      column: message.column,
      rule: message.ruleId || '(parser)',
      message: message.message
    }))
  );
  if (diagnostics.length > 0) {
    const details = diagnostics
      .map(({ file, line, column, rule, message }) => `${file}:${line}:${column}: ${rule}: ${message}`)
      .join('\n');
    throw new Error(`ESLint recommended debt must remain zero:\n${details}`);
  }
  process.stdout.write(`ESLint debt probe passed: 0 diagnostics across ${results.length} YAP-owned script files.\n`);
}

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
});
