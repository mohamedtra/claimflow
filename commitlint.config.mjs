export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Les résumés sont en français, en minuscules : on garde la règle de casse par défaut
    // mais on accepte les accents et les identifiants d'US dans le résumé.
    'subject-case': [2, 'never', ['upper-case', 'pascal-case', 'start-case']],
    'body-max-line-length': [2, 'always', 100],
    'scope-enum': [
      2,
      'always',
      [
        'sinistre', 'contrat', 'document', 'expertise', 'indemnisation', 'audit', 'notification',
        'pilotage', 'parametrage', 'shared', 'api', 'web', 'bff', 'infra', 'openapi', 'repo', 'ci',
        'deps',
      ],
    ],
  },
};
