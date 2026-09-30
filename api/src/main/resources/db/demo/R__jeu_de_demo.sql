-- Jeu de démonstration : les personnages de la maquette. Chargé uniquement avec le profil
-- « local » (spring.flyway.locations), jamais en rct ni en prod. Toutes les données sont fictives.
-- Les identifiants des collaborateurs sont ceux du realm Keycloak de démonstration.

INSERT INTO contrat.assure (id, utilisateur_id, nom, email, iban_masque) VALUES
    ('0192a3c4-0000-7000-8000-000000000001', '5b1f2c3d-0001-4a00-8000-00000000c1a1', 'Claire Martin',  'claire.martin@exemple.fr',  'FR76 •••• •••• •••• 4821'),
    ('0192a3c4-0000-7000-8000-000000000002', NULL,                                   'Thomas Girard',  'thomas.girard@exemple.fr',  'FR76 •••• •••• •••• 1177'),
    ('0192a3c4-0000-7000-8000-000000000003', NULL,                                   'Inès Bouaziz',   'ines.bouaziz@exemple.fr',   'FR76 •••• •••• •••• 9054'),
    ('0192a3c4-0000-7000-8000-000000000004', NULL,                                   'Lucas Petit',    'lucas.petit@exemple.fr',    'FR76 •••• •••• •••• 3310')
ON CONFLICT (id) DO NOTHING;

INSERT INTO contrat.contrat (id, numero, assure_id, type, libelle, debut, fin) VALUES
    ('0192a3c4-0000-7000-8000-000000000101', 'HAB-3391027',  '0192a3c4-0000-7000-8000-000000000001', 'HABITATION', 'Multirisque habitation', '2022-03-01', NULL),
    ('0192a3c4-0000-7000-8000-000000000102', 'AUTO-7712045', '0192a3c4-0000-7000-8000-000000000001', 'AUTO',       'Auto tous risques',      '2023-06-15', NULL),
    ('0192a3c4-0000-7000-8000-000000000103', 'AUTO-5520318', '0192a3c4-0000-7000-8000-000000000002', 'AUTO',       'Auto tiers étendu',      '2021-01-10', NULL),
    ('0192a3c4-0000-7000-8000-000000000104', 'HAB-2208716',  '0192a3c4-0000-7000-8000-000000000003', 'HABITATION', 'Multirisque habitation', '2024-09-01', NULL),
    ('0192a3c4-0000-7000-8000-000000000105', 'HAB-1983340',  '0192a3c4-0000-7000-8000-000000000004', 'HABITATION', 'Multirisque habitation', '2019-04-20', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO contrat.garantie (id, contrat_id, type, plafond, franchise, taux_vetuste) VALUES
    ('0192a3c4-0000-7000-8000-000000000201', '0192a3c4-0000-7000-8000-000000000101', 'DEGAT_DES_EAUX',  8000.00,  300.00, 15),
    ('0192a3c4-0000-7000-8000-000000000202', '0192a3c4-0000-7000-8000-000000000101', 'INCENDIE',       60000.00,  500.00, 10),
    ('0192a3c4-0000-7000-8000-000000000203', '0192a3c4-0000-7000-8000-000000000101', 'VOL',            15000.00,  250.00, 20),
    ('0192a3c4-0000-7000-8000-000000000204', '0192a3c4-0000-7000-8000-000000000101', 'TEMPETE',        20000.00,  380.00, 10),
    ('0192a3c4-0000-7000-8000-000000000205', '0192a3c4-0000-7000-8000-000000000102', 'AUTO_COLLISION', 25000.00,  400.00,  0),
    ('0192a3c4-0000-7000-8000-000000000206', '0192a3c4-0000-7000-8000-000000000102', 'AUTO_VANDALISME',25000.00,  400.00,  0),
    ('0192a3c4-0000-7000-8000-000000000207', '0192a3c4-0000-7000-8000-000000000102', 'BRIS_DE_GLACE',   3000.00,    0.00,  0),
    ('0192a3c4-0000-7000-8000-000000000208', '0192a3c4-0000-7000-8000-000000000103', 'AUTO_COLLISION', 15000.00,  500.00,  0),
    ('0192a3c4-0000-7000-8000-000000000209', '0192a3c4-0000-7000-8000-000000000104', 'VOL',            12000.00,  250.00, 20),
    ('0192a3c4-0000-7000-8000-000000000210', '0192a3c4-0000-7000-8000-000000000105', 'INCENDIE',       60000.00,  500.00, 10)
ON CONFLICT (id) DO NOTHING;

INSERT INTO parametrage.equipe (id, nom, specialite) VALUES
    ('0192a3c4-0000-7000-8000-000000000301', 'Habitation', 'HABITATION'),
    ('0192a3c4-0000-7000-8000-000000000302', 'Auto',       'AUTO')
ON CONFLICT (id) DO NOTHING;

INSERT INTO parametrage.collaborateur (id, nom, role, equipe_id) VALUES
    ('5b1f2c3d-0002-4a00-8000-00000000c1a2', 'Julien Moreau',  'GESTIONNAIRE', '0192a3c4-0000-7000-8000-000000000301'),
    ('5b1f2c3d-0003-4a00-8000-00000000c1a3', 'Amélie Roux',    'GESTIONNAIRE', '0192a3c4-0000-7000-8000-000000000302'),
    ('5b1f2c3d-0004-4a00-8000-00000000c1a4', 'Nadia Benali',   'EXPERT',       NULL),
    ('5b1f2c3d-0005-4a00-8000-00000000c1a5', 'Sophie Laurent', 'RESPONSABLE',  '0192a3c4-0000-7000-8000-000000000301'),
    ('5b1f2c3d-0006-4a00-8000-00000000c1a6', 'Karim Haddad',   'ADMIN',        NULL)
ON CONFLICT (id) DO NOTHING;
