-- Contrats de test (US-04, US-03). Dates relatives : le test reste valable dans le temps.
INSERT INTO contrat.assure (id, utilisateur_id, nom, email) VALUES
    ('00000000-0000-7000-8000-0000000000a1', '5b1f2c3d-0001-4a00-8000-00000000c1a1', 'Claire Martin', 'claire.test@exemple.fr'),
    ('00000000-0000-7000-8000-0000000000a2', '5b1f2c3d-0009-4a00-8000-00000000c1a9', 'Thomas Girard', 'thomas.test@exemple.fr')
ON CONFLICT DO NOTHING;

INSERT INTO contrat.contrat (id, numero, assure_id, type, libelle, debut, fin) VALUES
    -- Claire : un contrat actif, un échu depuis un an (visible), un échu depuis plus de trois ans (masqué)
    ('00000000-0000-7000-8000-0000000000c1', 'HAB-0000001',  '00000000-0000-7000-8000-0000000000a1', 'HABITATION', 'Multirisque habitation', current_date - 400,  NULL),
    ('00000000-0000-7000-8000-0000000000c2', 'AUTO-0000002', '00000000-0000-7000-8000-0000000000a1', 'AUTO',       'Auto tous risques',      current_date - 1500, current_date - 365),
    ('00000000-0000-7000-8000-0000000000c3', 'AUTO-0000003', '00000000-0000-7000-8000-0000000000a1', 'AUTO',       'Ancienne auto',          current_date - 3000, current_date - 1200),
    -- Thomas : ne doit jamais apparaître chez Claire
    ('00000000-0000-7000-8000-0000000000c4', 'HAB-0000004',  '00000000-0000-7000-8000-0000000000a2', 'HABITATION', 'Multirisque habitation', current_date - 100,  NULL)
ON CONFLICT DO NOTHING;

INSERT INTO contrat.garantie (id, contrat_id, type, plafond, franchise, taux_vetuste) VALUES
    ('00000000-0000-7000-8000-0000000000e1', '00000000-0000-7000-8000-0000000000c1', 'DEGAT_DES_EAUX',  8000.00, 300.00, 15),
    ('00000000-0000-7000-8000-0000000000e2', '00000000-0000-7000-8000-0000000000c1', 'INCENDIE',       60000.00, 500.00, 10),
    ('00000000-0000-7000-8000-0000000000e3', '00000000-0000-7000-8000-0000000000c2', 'AUTO_COLLISION', 25000.00, 400.00,  0),
    ('00000000-0000-7000-8000-0000000000e4', '00000000-0000-7000-8000-0000000000c4', 'VOL',            12000.00, 250.00, 20)
ON CONFLICT DO NOTHING;
