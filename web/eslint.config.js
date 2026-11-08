// @ts-check
const eslint = require('@eslint/js');
const { defineConfig } = require('eslint/config');
const tseslint = require('typescript-eslint');
const angular = require('angular-eslint');

module.exports = defineConfig([
  {
    name: 'claimflow/ignores',
    // src/app/api : code généré par ng-openapi-gen à partir du contrat (ADR-005), jamais modifié.
    ignores: ['dist/**', 'coverage/**', '.angular/**', 'src/app/api/**'],
  },
  {
    name: 'claimflow/typescript',
    files: ['**/*.ts'],
    extends: [
      eslint.configs.recommended,
      tseslint.configs.recommended,
      tseslint.configs.stylistic,
      angular.configs.tsRecommended,
    ],
    processor: angular.processInlineTemplates,
    rules: {
      '@angular-eslint/component-selector': ['error', { type: 'element', prefix: 'cf', style: 'kebab-case' }],
      '@angular-eslint/directive-selector': ['error', { type: 'attribute', prefix: 'cf', style: 'camelCase' }],
      // Composants rafraîchis par les signaux uniquement (application sans zone.js).
      '@angular-eslint/prefer-on-push-component-change-detection': 'error',
      // ADR-003 : aucun jeton dans le stockage du navigateur.
      'no-restricted-globals': [
        'error',
        { name: 'localStorage', message: 'Interdit pour les jetons (ADR-003). Utiliser le BFF.' },
        { name: 'sessionStorage', message: 'Interdit pour les jetons (ADR-003). Utiliser le BFF.' },
      ],
    },
  },
  {
    name: 'claimflow/gabarits',
    files: ['**/*.html'],
    extends: [angular.configs.templateRecommended, angular.configs.templateAccessibility],
    rules: {
      // Syntaxe de contrôle @if / @for, et non *ngIf / *ngFor.
      '@angular-eslint/template/prefer-control-flow': 'error',
    },
  },
]);
