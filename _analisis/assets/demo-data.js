// AvoOlio — dataset de ejemplo compartido por demo.html y app.html
window.AVO_DEMO = {
 semanas: [20, 21, 22],
 roles: ["Jefe de acopio", "Acopiador", "Admin acopio", "Tesorería", "Financiero", "Contador"],

 // --- CATÁLOGO MAESTRO: HUERTAS ---
 // La huerta guarda su punto de reunión y báscula habituales. Al programar un
 // corte, estos campos se autollenan desde aquí (y quedan editables).
 huertas: [
  { hue:"HUE00000002340", huerta:"El Fresno",   productor:"José Luis Magaña",           municipio:"Tancítaro",          altura:2340, punto_reunion:"Entronque carr. Tancítaro–Apo, km 4", bascula:"Báscula Tancítaro Centro" },
  { hue:"HUE00000002480", huerta:"Los Cedros",  productor:"María Elena Ruiz",           municipio:"Uruapan",            altura:2480, punto_reunion:"Caseta La Tzararacua",                  bascula:"Báscula Uruapan Norte" },
  { hue:"HUE00000002250", huerta:"San Isidro",  productor:"Grupo Aguacatero El Fresno", municipio:"Peribán",            altura:2250, punto_reunion:"Plaza Peribán, frente a la iglesia",     bascula:"Báscula Peribán" },
  { hue:"HUE00000002210", huerta:"La Esperanza",productor:"Ricardo Martínez",           municipio:"Peribán",            altura:2210, punto_reunion:"Desviación Los Reyes, km 8",            bascula:"Báscula Peribán" },
  { hue:"HUE00000001980", huerta:"El Mirador",  productor:"Juan Hernández",             municipio:"Salvador Escalante", altura:1980, punto_reunion:"Tienda La Soledad, Santa Clara",        bascula:"Báscula Salvador Escalante" },
  { hue:"HUE00000002050", huerta:"El Zapote",   productor:"Aurora León",                municipio:"Salvador Escalante", altura:2050, punto_reunion:"Crucero Opopeo",                       bascula:"Báscula Salvador Escalante" },
  { hue:"HUE00000002280", huerta:"La Joya",     productor:"Marisol Ávila",              municipio:"Tacámbaro",          altura:2280, punto_reunion:"Gasolinera Tacámbaro, salida sur",     bascula:"Báscula Tacámbaro" },
 ],

 // --- CATÁLOGO: PRODUCTORES ---
 productores: [
  { nombre:"José Luis Magaña",           rfc:"MAGJ820312H4A", municipio:"Tancítaro",          tel:"452 118 2240", huertas:2 },
  { nombre:"María Elena Ruiz",           rfc:"RUME750901K22", municipio:"Uruapan",            tel:"452 144 9087", huertas:1 },
  { nombre:"Grupo Aguacatero El Fresno", rfc:"GAF1903155Z9",  municipio:"Peribán",            tel:"354 102 3311", huertas:3 },
  { nombre:"Ricardo Martínez",           rfc:"MARR880214Q18", municipio:"Peribán",            tel:"354 119 7755", huertas:1 },
  { nombre:"Juan Hernández",             rfc:"HEJU690712T05", municipio:"Salvador Escalante", tel:"452 166 4420", huertas:1 },
  { nombre:"Marisol Ávila",              rfc:"AIMA910530B71", municipio:"Tacámbaro",          tel:"459 110 5562", huertas:2 },
 ],

 // --- CATÁLOGO: ACOPIADORES (core.acopista / v_acopistas_autorizados) ---
 acopiadores: [
  { nombre:"Roberto Salgado",  wa:"452 100 8841", zona:"Peribán / Los Reyes",     estatus:"Autorizado" },
  { nombre:"Laura Cervantes",  wa:"452 133 2019", zona:"Uruapan / Tancítaro",     estatus:"Autorizado" },
  { nombre:"Miguel Tapia",     wa:"459 120 6610", zona:"Tacámbaro / Ario",        estatus:"Autorizado" },
  { nombre:"Coyote (temporal)",wa:"—",            zona:"Salvador Escalante",      estatus:"Código temporal" },
 ],

 cortes: [
  // Semana 22 — 18.4 t
  { semana:22, grupo:"confirmado", huerta:"Huerta El Fresno",   productor:"José Luis Magaña",            municipio:"Tancítaro",        altura:2340, empresa:"Cuadrilla Sierra Verde",   precio:61.80, vol:4200 },
  { semana:22, grupo:"confirmado", huerta:"Huerta Los Cedros",  productor:"María Elena Ruiz",            municipio:"Uruapan",          altura:2480, empresa:"AgroServicios Purépecha", precio:63.20, vol:4200 },
  { semana:22, grupo:"confirmado", huerta:"Huerta San Isidro",  productor:"Grupo Aguacatero El Fresno",  municipio:"Peribán",          altura:2250, empresa:"Cuadrilla Sierra Verde",   precio:62.50, vol:4200 },
  { semana:22, grupo:"pendiente",  huerta:"Huerta La Esperanza", productor:"Ricardo Martínez",          municipio:"Peribán",          altura:2210, empresa:"Sin asignar",             precio:60.90, vol:2400 },
  { semana:22, grupo:"pendiente",  huerta:"Huerta San Miguel",  productor:"Fernando Gómez",              municipio:"Ario de Rosales",  altura:2150, empresa:"Sin asignar",             precio:59.70, vol:2400 },
  { semana:22, grupo:"alerta",     huerta:"Huerta El Mirador",  productor:"Juan Hernández",              municipio:"Salvador Escalante", altura:1980, empresa:"Cuadrilla Norte",       precio:58.50, vol:1000 },
  // Semana 21 — 16.9 t
  { semana:21, grupo:"confirmado", huerta:"Huerta La Joya",     productor:"Marisol Ávila",               municipio:"Tacámbaro",        altura:2280, empresa:"Cuadrilla Sierra Verde",   precio:60.00, vol:6300 },
  { semana:21, grupo:"confirmado", huerta:"Huerta El Capulín",  productor:"Raúl Mendoza",                municipio:"Peribán",          altura:2200, empresa:"AgroServicios Purépecha", precio:59.50, vol:5600 },
  { semana:21, grupo:"pendiente",  huerta:"Huerta Buenavista",  productor:"Lupita Ramos",                municipio:"Ario de Rosales",  altura:2150, empresa:"Sin asignar",             precio:58.50, vol:5000 },
  // Semana 20 — 15.2 t
  { semana:20, grupo:"confirmado", huerta:"Huerta San Isidro",  productor:"Tomás Cruz",                  municipio:"Tacámbaro",        altura:2330, empresa:"Cuadrilla Sierra Verde",   precio:57.00, vol:5200 },
  { semana:20, grupo:"confirmado", huerta:"Huerta El Capulín",  productor:"Raúl Mendoza",                municipio:"Peribán",          altura:2200, empresa:"AgroServicios Purépecha", precio:56.50, vol:4800 },
  { semana:20, grupo:"pendiente",  huerta:"Huerta Buenavista",  productor:"Lupita Ramos",                municipio:"Ario de Rosales",  altura:2150, empresa:"Sin asignar",             precio:56.90, vol:4200 },
  { semana:20, grupo:"alerta",     huerta:"Huerta El Zapote",   productor:"Aurora León",                 municipio:"Salvador Escalante", altura:2050, empresa:"Cuadrilla Norte",       precio:55.00, vol:1000 },
 ],
 kpi: {
  20: { por_pagar:980000,  vence_dias:7, vence_monto:312000, huertas:19 },
  21: { por_pagar:1080000, vence_dias:7, vence_monto:368500, huertas:20 },
  22: { por_pagar:1200000, vence_dias:7, vence_monto:420450, huertas:23 },
 },
 cxp: [
  // Semana 22
  { semana:22, tipo:"productor",       beneficiario:"José Luis Magaña",        factura:"CFDI A-1182",  monto:259560, status:"conciliada" },
  { semana:22, tipo:"servicio_corte",  beneficiario:"Cuadrilla Sierra Verde",  factura:"CFDI SV-440",  monto:42000,  status:"pagada" },
  { semana:22, tipo:"acarreo",         beneficiario:"Fletes del Bajío",        factura:null,           monto:8500,   status:"borrador" },
  { semana:22, tipo:"comision_acopio", beneficiario:"Acopiador R. Salgado",    factura:null,           monto:14200,  status:"borrador" },
  { semana:22, tipo:"productor",       beneficiario:"María Elena Ruiz",        factura:"CFDI MER-77",  monto:265440, status:"autorizada" },
  // Semana 21
  { semana:21, tipo:"productor",       beneficiario:"Marisol Ávila",           factura:"CFDI MA-310",  monto:378000, status:"conciliada" },
  { semana:21, tipo:"servicio_corte",  beneficiario:"Cuadrilla Sierra Verde",  factura:"CFDI SV-431",  monto:38500,  status:"pagada" },
  { semana:21, tipo:"acarreo",         beneficiario:"Transportes Uruapan",     factura:"CFDI TU-58",   monto:7800,   status:"pagada" },
  { semana:21, tipo:"comision_acopio", beneficiario:"Acopiador R. Salgado",    factura:null,           monto:11400,  status:"borrador" },
  // Semana 20
  { semana:20, tipo:"productor",       beneficiario:"Tomás Cruz",              factura:"CFDI TC-204",  monto:296400, status:"conciliada" },
  { semana:20, tipo:"servicio_corte",  beneficiario:"Cuadrilla Sierra Verde",  factura:"CFDI SV-420",  monto:35000,  status:"conciliada" },
  { semana:20, tipo:"acarreo",         beneficiario:"Fletes del Bajío",        factura:null,           monto:8500,   status:"borrador" },
 ],
 costeo: [
  { semana:20, costo_kilo:68.40, directos:1102000, indirectos:88000, curva:[["48s",72.5],["60s",70.1],["70s",68.4],["84s",65.8],["110s",62.4]] },
  { semana:21, costo_kilo:67.50, directos:1184000, indirectos:91000, curva:[["48s",71.0],["60s",69.0],["70s",67.5],["84s",64.9],["110s",61.5]] },
  { semana:22, costo_kilo:66.30, directos:1281000, indirectos:95000, curva:[["48s",70.5],["60s",68.0],["70s",66.3],["84s",63.5],["110s",60.2]] },
 ],
 // Cuadrillas y acarreo se quedan como catálogos genéricos (tabla simple).
 catalogos: [
  { titulo:"Empresas de corte / cuadrillas", cols:["Empresa","Tipo","Tarifa $/kg","Tarifa $/día"],
    filas:[
     ["Cuadrilla Sierra Verde","Propia","$0.85","$3,200"],
     ["AgroServicios Purépecha","Externa","$0.90","$3,500"],
     ["Cuadrilla Norte","Propia","$0.85","$3,200"],
    ] },
  { titulo:"Proveedores de acarreo", cols:["Proveedor","Tipo de unidad","Tarifa $/viaje"],
    filas:[
     ["Fletes del Bajío","Torton","$8,500"],
     ["Transportes Uruapan","Rabón","$6,200"],
     ["Particular (Don Chuy)","Camioneta 3.5t","$3,800"],
    ] },
 ],
};
