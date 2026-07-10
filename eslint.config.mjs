import js from '@eslint/js';
import globals from 'globals';

const RECOMMENDED_RULES = js.configs.recommended.rules;

export default [
  {
    ignores: ['assets/**', 'dist/**', 'node_modules/**', 'wwwroot/**']
  },
  {
    linterOptions: {
      noInlineConfig: true,
      reportUnusedDisableDirectives: 'error'
    }
  },
  {
    files: ['scripts/**/*.js'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'commonjs',
      globals: globals.node
    },
    rules: RECOMMENDED_RULES
  },
  {
    files: ['scripts/**/*.mjs'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: globals.node
    },
    rules: RECOMMENDED_RULES
  }
];
