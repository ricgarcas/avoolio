-- =============================================================================
-- 0002_acopio_pendientes_seed.sql
-- Datos de muestra para ver la cola de Pendientes viva mientras llega el import
-- real de Monday.com. Idempotente: limpia y re-inserta.
-- Hace eco del mockup del spec (Supervisor · cola de Pendientes).
-- =============================================================================

truncate table public.pendiente_hitl;

insert into public.pendiente_hitl
  (created_at, codigo_hue, huerta, empacadora, productor, acopio, acopiador, variedad,
   calibre, banda, precio_propuesto_mxn_kg, precio_banda_max_mxn_kg,
   volumen_acordado_kg, margen_pct, tipo, razon_hitl)
values
  (now() - interval '22 min', 'HUE08160530011', 'La Esperanza', 'Avoolio', 'Juan Pérez', 'Tancítaro', 'Juan P.', 'Hass',
   48, 7, 42.00, 41.10, 12000, -2.30, 'fuera_margen',
   'Cal 48 abierta · 12 ton faltantes · cierre 26 may. Productor con 4 acuerdos previos, score A. Acopiador score A, 0% salidas falsas.'),

  (now() - interval '14 min', 'HUE08160530023', 'El Roble', 'Avoolio', 'M. Hernández', 'Peribán', 'M. Hernández', 'Hass',
   40, 7, 40.20, 39.80, 9400, -1.10, 'fuera_margen',
   'Banda 7 · sobreprecio leve para cerrar volumen de cal 40 comprometido con importador.'),

  (now() - interval '8 min', 'HUE08160530087', 'Don Pedro', 'Avoolio', 'Juan Pérez', 'Tancítaro', 'Juan P.', 'Hass',
   36, NULL, 46.40, 38.50, 6800, -8.40, 'coyote',
   'Precio muy por encima de mercado (coyoteo detectado). Requiere validación del supervisor antes de cerrar.'),

  (now() - interval '5 min', 'HUE08160530190', 'La Cumbre', 'Avoolio', 'C. Ramos', 'Uruapan', 'C. Ramos', 'Hass',
   48, 6, 38.80, 40.20, 11200, 1.40, 'modificacion',
   'Acopiador solicita modificar calibre objetivo de 48 a 60 tras revisar la huerta en sitio.'),

  (now() - interval '3 min', 'HUE08160530142', 'Las Palmas', 'Avoolio', 'Salvador Díaz', 'Los Reyes', 'S. Díaz', 'Hass',
   60, 5, 32.50, 33.40, 8200, 0.60, 'fuera_margen',
   'Banda 5 · cal 60 con demanda baja esta semana; margen ajustado pero positivo.'),

  (now() - interval '2 min', 'HUE08160530206', 'San Antonio', 'Avoolio', 'Juan Pérez', 'Tancítaro', 'Juan P.', 'Hass',
   72, NULL, 28.20, 25.00, 5400, -9.10, 'coyote',
   'Precio fuera de rango para cal 72 (coyoteo). Productor nuevo, sin historial — score pendiente.');
