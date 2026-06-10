-- Seed de test con UUIDs fijos. Convención:
--   ...0001/0002 empacadoras · ...001x periodos · ...002x cuentas
--   ...003x actores · ...004x ordenes
INSERT INTO public.empacadora (id, nombre) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Empacadora A (test)'),
  ('00000000-0000-0000-0000-000000000002', 'Empacadora B (test)');

INSERT INTO public.importador (id, nombre_empresa) VALUES
  ('00000000-0000-0000-0000-000000000031', 'Importador Test LLC');

INSERT INTO public.productor (id, nombre) VALUES
  ('00000000-0000-0000-0000-000000000032', 'Productor Test');

INSERT INTO public.cuadrilla (id, nombre) VALUES
  ('00000000-0000-0000-0000-000000000033', 'Cuadrilla Test');

INSERT INTO public.orden_venta (id, empacadora_id, importador_id, total_usd, fecha_entrega_real) VALUES
  ('00000000-0000-0000-0000-000000000041',
   '00000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000031',
   10000.00, '2026-06-01');

-- Periodos para empacadora A: junio abierto, mayo cerrado.
INSERT INTO contabilidad.periodo_contable (id, empacadora_id, anio, mes, fecha_inicio, fecha_fin, estado) VALUES
  ('00000000-0000-0000-0000-000000000011',
   '00000000-0000-0000-0000-000000000001', 2026, 6, '2026-06-01', '2026-06-30', 'abierto'),
  ('00000000-0000-0000-0000-000000000012',
   '00000000-0000-0000-0000-000000000001', 2026, 5, '2026-05-01', '2026-05-31', 'cerrado');

-- Catálogo mínimo para A: grupo (no hoja), dos hojas activas, una hoja inactiva.
INSERT INTO contabilidad.cuenta_contable (id, empacadora_id, codigo, nombre, tipo, naturaleza, cuenta_padre_id, es_hoja, activa) VALUES
  ('00000000-0000-0000-0000-000000000020',
   '00000000-0000-0000-0000-000000000001', '1000', 'Activo', 'activo', 'deudora', NULL, FALSE, TRUE),
  ('00000000-0000-0000-0000-000000000021',
   '00000000-0000-0000-0000-000000000001', '1100', 'Bancos MXN', 'activo', 'deudora',
   '00000000-0000-0000-0000-000000000020', TRUE, TRUE),
  ('00000000-0000-0000-0000-000000000022',
   '00000000-0000-0000-0000-000000000001', '4100', 'Venta Export USD', 'ingreso', 'acreedora', NULL, TRUE, TRUE),
  ('00000000-0000-0000-0000-000000000023',
   '00000000-0000-0000-0000-000000000001', '5999', 'Cuenta Inactiva', 'egreso', 'deudora', NULL, TRUE, FALSE);

-- Una fila contable por tenant para los tests de RLS.
INSERT INTO contabilidad.cuenta_contable (id, empacadora_id, codigo, nombre, tipo, naturaleza, es_hoja, activa) VALUES
  ('00000000-0000-0000-0000-000000000024',
   '00000000-0000-0000-0000-000000000002', '1100', 'Bancos MXN (B)', 'activo', 'deudora', TRUE, TRUE);
