// AvoOlio — interacciones compartidas (vanilla, sin build)

// Marca el link activo en el nav + acordeones
document.addEventListener('DOMContentLoaded', () => {
  const here = location.pathname.split('/').pop() || 'index.html';
  document.querySelectorAll('.topbar nav a').forEach(a => {
    if (a.getAttribute('href') === here) a.classList.add('active');
  });
  document.querySelectorAll('.acc-head').forEach(h => {
    h.addEventListener('click', () => h.parentElement.classList.toggle('open'));
  });
});

// Explorador de entidades (ER). Espera window.AVO_ENTITIES definido en la página.
function initEntityExplorer() {
  const data = window.AVO_ENTITIES;
  if (!data) return;
  const list = document.getElementById('er-list');
  const detail = document.getElementById('er-detail');
  const keys = Object.keys(data);

  function render(key) {
    const e = data[key];
    list.querySelectorAll('.er-item').forEach(b => b.classList.toggle('active', b.dataset.k === key));
    const fields = e.fields.map(f =>
      `<tr><td>${f[0]}</td><td>${f[1]}</td><td>${f[2]}</td></tr>`).join('');
    const rules = (e.rules || []).map(r =>
      `<div class="rule"><span class="lock">🔒</span><div>${r}</div></div>`).join('');
    detail.innerHTML = `
      <span class="pill ${e.kind === 'op' ? 'info' : 'ok'}">${e.kind === 'op' ? 'Operativa · viene de la captura' : 'Contable · por modelar'}</span>
      <h3>${e.title} <code>${key}</code></h3>
      <p>${e.desc}</p>
      <table class="fields"><tbody>${fields}</tbody></table>
      ${rules ? `<h4 style="margin-top:18px;color:var(--danger)">Candados / reglas</h4>${rules}` : ''}
      ${e.note ? `<div class="callout info" style="margin-top:16px">${e.note}</div>` : ''}
    `;
  }

  list.innerHTML = keys.map(k => {
    const e = data[k];
    return `<button class="er-item" data-k="${k}"><span class="dotk ${e.kind === 'op' ? 'op' : 'acc'}"></span>${e.title}</button>`;
  }).join('');
  list.querySelectorAll('.er-item').forEach(b => b.addEventListener('click', () => render(b.dataset.k)));
  render(keys[0]);
}

// ---------- App demo: recreación de la pantalla de gestión ----------
// Espera window.AVO_DEMO + un contenedor #appdemo.
function initAppDemo() {
  const D = window.AVO_DEMO;
  const root = document.getElementById('appdemo');
  if (!D || !root) return;

  let week = D.semanas[D.semanas.length - 1];
  let view = 'catalogos';
  let roleIdx = 0;

  const money  = n => '$' + Math.round(n).toLocaleString('es-MX');
  const moneyM = n => n >= 1e6 ? '$' + (n / 1e6).toFixed(1) + ' M' : '$' + Math.round(n / 1000) + 'K';
  const tons   = kg => (kg / 1000).toFixed(1) + ' t';
  const svg = p => `<svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">${p}</svg>`;
  const ICON = {
    cortes:    svg('<rect x="3" y="4.5" width="18" height="16.5" rx="2"/><path d="M3 9.5h18M8 2.5v4M16 2.5v4"/>'),
    cxp:       svg('<rect x="2.5" y="5.5" width="19" height="13" rx="2"/><path d="M2.5 10h19"/>'),
    facturas:  svg('<path d="M6 2.5h8l4 4V21H6z"/><path d="M9 11h6M9 15h6"/>'),
    pagos:     svg('<rect x="3" y="6" width="18" height="12" rx="2"/><circle cx="12" cy="12" r="2.4"/>'),
    costeo:    svg('<path d="M12 3.5a8.5 8.5 0 1 0 8.5 8.5H12z"/><path d="M12 3.5v8.5h8.5" opacity=".4"/>'),
    catalogos: svg('<rect x="3.5" y="3.5" width="7" height="7" rx="1"/><rect x="13.5" y="3.5" width="7" height="7" rx="1"/><rect x="3.5" y="13.5" width="7" height="7" rx="1"/><rect x="13.5" y="13.5" width="7" height="7" rx="1"/>'),
  };
  const NAV = [['catalogos', 'Catálogos'], ['cortes', 'Cortes'], ['cxp', 'Cuentas por pagar'], ['facturas', 'Facturas'], ['pagos', 'Pagos'], ['costeo', 'Costeo']];
  const TITLES = { cortes: 'Programación de corte', cxp: 'Cuentas por pagar', facturas: 'Facturas', pagos: 'Pagos', costeo: 'Costeo semanal', catalogos: 'Catálogos' };

  const prevOf    = w => { const i = D.semanas.indexOf(w); return i > 0 ? D.semanas[i - 1] : null; };
  const volWeek   = w => D.cortes.filter(c => c.semana === w).reduce((s, c) => s + c.vol, 0);
  const costoWeek = w => (D.costeo.find(x => x.semana === w) || {}).costo_kilo || 0;

  function deltaHtml(cur, prev, goodUp, isPct) {
    if (prev == null || prev === 0) return `<span class="muted2">— sin comparativa</span>`;
    const diff = cur - prev, up = diff > 0, good = goodUp ? up : !up;
    const val = isPct ? Math.abs(diff / prev * 100).toFixed(1) + '%' : Math.abs(diff);
    return `<span class="d ${good ? 'up' : 'down'}">${up ? '↑' : '↓'} ${val}</span> <span class="muted2">vs semana ${prevOf(week)}</span>`;
  }

  function side() {
    const role = D.roles[roleIdx];
    return `<aside class="app-side">
      <div class="app-brand"><img src="assets/gota-avoolio.png" alt=""><span class="wm">Avo<b>Olio</b></span></div>
      <nav class="app-nav">${NAV.map(([k, l]) => `<button class="nav-i ${k === view ? 'active' : ''}" data-v="${k}">${ICON[k]}${l}</button>`).join('')}</nav>
      <div class="app-user">
        <div class="who"><span class="av">LC</span><div><div class="nm">Luis Contreras</div><div class="ro">${role}</div></div></div>
        <div class="switch-lbl">Cambiar rol</div>
        <select class="role-sel">${D.roles.map((r, i) => `<option ${i === roleIdx ? 'selected' : ''}>${r}</option>`).join('')}</select>
      </div>
    </aside>`;
  }

  function kpiStrip() {
    const k = D.kpi[week] || {}, pw = prevOf(week);
    const cVol = volWeek(week), pVol = pw != null ? volWeek(pw) : null;
    const cCosto = costoWeek(week), pCosto = pw != null ? costoWeek(pw) : null;
    const pK = pw != null ? D.kpi[pw] : null;
    const dollar = `<span style="font-family:var(--display);font-size:1.2rem">$</span>`;
    const box  = svg('<rect x="3.5" y="7" width="17" height="13" rx="2"/><path d="M3.5 11h17M12 7v13"/>');
    const card = svg('<rect x="3" y="6" width="18" height="12" rx="2"/><path d="M3 10h18"/>');
    const tree = svg('<path d="M12 3l5 8H7z"/><path d="M12 9l4 7H8z"/><path d="M12 16v5"/>');
    return `<div class="kpi-strip">
      <div class="kc"><div class="top"><div class="icn green">${dollar}</div><div><div class="lbl">Costo por kilo</div><div class="val">$${cCosto.toFixed(2)}</div></div></div><div class="dl">${deltaHtml(cCosto, pCosto, false, true)}</div></div>
      <div class="kc"><div class="top"><div class="icn olive">${box}</div><div><div class="lbl">Volumen programado</div><div class="val">${tons(cVol)}</div></div></div><div class="dl">${deltaHtml(cVol, pVol, true, true)}</div></div>
      <div class="kc"><div class="top"><div class="icn gold">${card}</div><div><div class="lbl">Por pagar</div><div class="val">${moneyM(k.por_pagar || 0)}</div></div></div><div class="sub">Vence en ${k.vence_dias} días: ${money(k.vence_monto)}</div></div>
      <div class="kc"><div class="top"><div class="icn green">${tree}</div><div><div class="lbl">Huertas activas</div><div class="val">${k.huertas}</div></div></div><div class="dl">${deltaHtml(k.huertas, pK ? pK.huertas : null, true, false)}</div></div>
    </div>`;
  }

  function weekRow() {
    return `<div class="app-weekrow">
      <span class="rail-foot">↻ Última actualización: hoy 08:35 a.m.</span>
      <div class="app-weeks"><span class="lbl">Semana</span>${D.semanas.map(w => `<button class="app-wk ${w === week ? 'active' : ''}" data-w="${w}">${w}</button>`).join('')}</div>
    </div>`;
  }
  function header(acts) {
    const search = `<div class="app-search">${svg('<circle cx="11" cy="11" r="7"/><path d="M21 21l-4-4"/>')}Buscar huerta o productor</div>`;
    return `<div class="app-h"><h3>${TITLES[view]}</h3><span class="sp"></span>${search}<div class="app-acts">${acts || ''}</div></div>`;
  }

  function cortesPane() {
    const GROUPS = [
      { key: 'confirmado', cls: 'green', title: 'Cortes confirmados',            badge: ['ok', 'Confirmado'] },
      { key: 'pendiente',  cls: 'gold',  title: 'Pendientes de cuadrilla',       badge: ['wait', 'Pendiente'] },
      { key: 'alerta',     cls: 'red',   title: 'Alerta de altura &lt;2100 · plaga', badge: ['stuck', 'Requiere supervisor'] },
    ];
    const rows = D.cortes.filter(c => c.semana === week);
    const cols = `<tr><th style="width:34px"></th><th>Huerta</th><th>Productor</th><th>Municipio</th><th>Altura (msnm)</th><th>Empresa corte</th><th>Status</th><th>Precio pactado</th><th style="width:30px"></th></tr>`;
    const body = GROUPS.map(g => {
      const gr = rows.filter(r => r.grupo === g.key);
      if (!gr.length) return '';
      const vol = gr.reduce((s, r) => s + r.vol, 0);
      const trs = gr.map(r => `<tr class="${g.key === 'alerta' ? 'alert' : ''}${r.nuevo ? ' nuevo' : ''}">
        <td class="lead-cell"><span class="chk"></span></td>
        <td class="hu">${r.huerta}</td><td>${r.productor}</td><td>${r.municipio}</td>
        <td class="alt">${r.altura.toLocaleString('es-MX')}</td><td>${r.empresa}</td>
        <td><span class="cbadge ${g.badge[0]}">${g.badge[1]}</span></td>
        <td class="pr">${r.precio ? '$' + r.precio.toFixed(2) + ' /kg' : '—'}</td>
        <td><span class="ddots">⋯</span></td></tr>`).join('');
      return `<div class="cgroup ${g.cls}">
        <div class="cgroup-head"><span class="chev2">▾</span><span class="ttl">${g.title}</span><span class="cnt">${gr.length}</span><span class="vol">Volumen: ${tons(vol)}</span></div>
        <table class="ctable"><thead>${cols}</thead><tbody>${trs}</tbody></table>
        <div class="addrow">＋ Agregar corte</div></div>`;
    }).join('');
    const acts = `<button class="app-btn">⚲ Filtros</button><button class="app-btn">⤓ Exportar</button><button class="app-btn icon">⋯</button><button class="app-btn primary" data-corte>＋ Programar corte</button>`;
    return header(acts) + body;
  }

  function cxpPane() {
    const rows = D.cxp.filter(c => c.semana === week);
    const tipos = { productor: 'Productor', servicio_corte: 'Servicio de corte', acarreo: 'Acarreo', comision_acopio: 'Comisión de acopio' };
    const stMap = { borrador: ['wait', 'Borrador'], validada: ['ok', 'Validada'], autorizada: ['ok', 'Autorizada'], pagada: ['ok', 'Pagada'], conciliada: ['ok', 'Conciliada'] };
    const total = rows.reduce((s, r) => s + r.monto, 0);
    const trs = rows.map(r => {
      const [c, l] = stMap[r.status], canPay = !!r.factura;
      return `<tr>
        <td class="lead-cell">${tipos[r.tipo]}</td><td>${r.beneficiario}</td>
        <td>${canPay ? `<span class="cbadge ok">✓ ${r.factura}</span>` : `<span class="cbadge stuck">Sin factura</span> <span class="lockic">🔒</span>`}</td>
        <td style="font-family:var(--mono)">${money(r.monto)}</td>
        <td><span class="cbadge ${c}">${l}</span></td>
        <td>${canPay ? '' : '<span class="muted" style="font-size:.78rem">no se puede pagar</span>'}</td></tr>`;
    }).join('');
    const t = `<table class="ctable"><thead><tr><th>Tipo</th><th>Beneficiario</th><th>Factura</th><th>Monto final</th><th>Status</th><th></th></tr></thead>
      <tbody>${trs}<tr><td class="lead-cell" colspan="3" style="font-weight:700">Total obligaciones · Semana ${week}</td><td style="font-family:var(--mono);font-weight:700">${money(total)}</td><td colspan="2"></td></tr></tbody></table>`;
    const note = `<div class="callout danger" style="margin-top:14px"><strong>🔒 Candado de factura en vivo.</strong> Las filas <span class="cbadge stuck" style="font-size:.7rem">Sin factura</span> no pueden avanzar a <em>Pagada</em>: el status se bloquea hasta que administración valide el CFDI. La única salida es registrar una <code>excepcion_pago</code> autorizada. (Distinto del candado de altura, que es de supervisión, no de pago.)</div>`;
    return header('') + t + note;
  }

  function costeoPane() {
    const c = D.costeo.find(x => x.semana === week);
    if (!c) return header('') + '<div class="soon">Sin costeo para esta semana.</div>';
    const maxv = Math.max(...c.curva.map(x => x[1]));
    const bars = c.curva.map(x => `<div class="bar"><div class="cv">$${x[1].toFixed(0)}</div><div class="fill" style="height:${Math.round(x[1] / maxv * 100)}%"></div><div class="cl">${x[0]}</div></div>`).join('');
    return header('') + `
      <div class="grid c3" style="margin:6px 0 18px">
        <div class="kc"><div class="lbl">Costo por kilo (ponderado)</div><div class="val">$${c.costo_kilo.toFixed(2)}</div></div>
        <div class="kc"><div class="lbl">Directos (CxP)</div><div class="val">${moneyM(c.directos)}</div></div>
        <div class="kc"><div class="lbl">Indirectos prorrateados</div><div class="val">${moneyM(c.indirectos)}</div></div>
      </div>
      <h3 style="font-family:var(--head);font-size:1.05rem;margin:0 0 4px">Costo por curva de calibre</h3>
      <div class="curve">${bars}</div>
      <div class="callout"><strong>El reporte cumbre:</strong> "¿cuánto me costó comprar un kilo con servicios esta semana?" — sumando, por calibre, todas las CxP de la semana más los indirectos prorrateados.</div>`;
  }

  function catTable(titulo, cols, rows) {
    return `<h3 style="font-family:var(--head);font-size:1.05rem">${titulo} <span class="cnt">${rows.length}</span></h3>
      <table class="ctable" style="margin-bottom:22px"><thead><tr>${cols.map(h => `<th>${h}</th>`).join('')}</tr></thead>
      <tbody>${rows.map(r => `<tr>${r.map((v, i) => `<td class="${i === 0 ? 'lead-cell hu' : ''}">${v}</td>`).join('')}</tr>`).join('')}</tbody></table>`;
  }

  function catalogosPane() {
    const acts = `<button class="app-btn">⤓ Exportar</button><button class="app-btn primary" data-corte>＋ Programar corte</button>`;
    const intro = `<div class="fillnote">ⓘ Estos catálogos son la base maestra del acopio. Al <strong>programar un corte</strong>, los datos de la huerta (punto de reunión, báscula, productor…) se autollenan desde aquí.</div>`;

    const huertas = catTable('Huertas', ['HUE', 'Huerta', 'Productor', 'Municipio', 'Altura', 'Punto de reunión', 'Báscula'],
      D.huertas.map(h => [
        `<span style="font-family:var(--mono);font-size:.78rem">${h.hue}</span>`,
        h.huerta, h.productor, h.municipio,
        h.altura < 2100 ? `<span style="color:var(--brick);font-weight:700">${h.altura.toLocaleString('es-MX')} ⚠</span>` : h.altura.toLocaleString('es-MX'),
        h.punto_reunion, h.bascula,
      ]));

    const productores = catTable('Productores', ['Productor', 'RFC', 'Municipio', 'Teléfono', 'Huertas'],
      D.productores.map(p => [p.nombre, `<span style="font-family:var(--mono);font-size:.78rem">${p.rfc}</span>`, p.municipio, p.tel, p.huertas]));

    const acopiadores = catTable('Acopiadores', ['Acopiador', 'WhatsApp', 'Zona', 'Estatus'],
      D.acopiadores.map(a => [a.nombre, a.wa, a.zona,
        a.estatus === 'Autorizado' ? `<span class="cbadge ok">${a.estatus}</span>` : `<span class="cbadge wait">${a.estatus}</span>`]));

    const genericos = D.catalogos.map(c => catTable(c.titulo, c.cols, c.filas)).join('');

    return header(acts) + intro + huertas + productores + acopiadores + genericos;
  }

  // ---------- Modal: Programar corte (autollenado desde catálogo de huertas) ----------
  function openCorteModal() {
    if (document.querySelector('.modal-overlay')) return;
    const cuadrillas = (D.catalogos.find(c => /corte/i.test(c.titulo)) || { filas: [] }).filas.map(f => f[0]);
    const ov = document.createElement('div');
    ov.className = 'modal-overlay';
    ov.innerHTML = `
      <div class="modal" role="dialog" aria-modal="true">
        <div class="modal-head"><h3>Programar corte</h3><button class="x" data-close aria-label="Cerrar">✕</button></div>
        <div class="modal-body">
          <p class="modal-sub">Elige la huerta y el resto se llena solo desde el catálogo. Puedes editar cualquier campo.</p>
          <div class="fgrid">
            <div class="field full">
              <label>Huerta (HUE)</label>
              <select id="m-huerta">
                <option value="">— Selecciona una huerta —</option>
                ${D.huertas.map((h, i) => `<option value="${i}">${h.huerta} · ${h.hue}</option>`).join('')}
              </select>
            </div>
            <div class="field"><label>Productor</label><input id="m-productor" placeholder="—"></div>
            <div class="field"><label>Municipio</label><input id="m-municipio" placeholder="—"></div>
            <div class="field"><label>Altura (msnm)</label><input id="m-altura" placeholder="—"></div>
            <div class="field"><label>Báscula</label><input id="m-bascula" placeholder="—"></div>
            <div class="field full"><label>Punto de reunión</label><input id="m-punto" placeholder="—"></div>
            <div class="alt-alert" id="m-alert"><span>⚠</span><div><strong>Alerta de altura (&lt;2100 msnm).</strong> Riesgo de gusano barrenador. El corte requerirá aceptación de riesgo del supervisor.</div></div>
            <div class="field"><label>Empresa de corte / cuadrilla</label>
              <select id="m-cuadrilla"><option value="">Sin asignar</option>${cuadrillas.map(c => `<option>${c}</option>`).join('')}</select>
            </div>
            <div class="field"><label>Volumen estimado (kg)</label><input id="m-vol" placeholder="ej. 4200"></div>
          </div>
        </div>
        <div class="modal-foot">
          <span class="hint" style="color:var(--ink-soft);font-size:.82rem">Semana ${week}</span>
          <span class="sp"></span>
          <button class="app-btn" data-close>Cancelar</button>
          <button class="app-btn primary" id="m-save">Programar corte</button>
        </div>
      </div>`;
    document.body.appendChild(ov);

    const $ = id => ov.querySelector(id);
    const fill = (el, val) => { el.value = val; el.classList.remove('filled'); void el.offsetWidth; el.classList.add('filled'); };

    $('#m-huerta').addEventListener('change', e => {
      const h = D.huertas[e.target.value];
      if (!h) return;
      fill($('#m-productor'), h.productor);
      fill($('#m-municipio'), h.municipio);
      fill($('#m-altura'), h.altura);
      fill($('#m-bascula'), h.bascula);
      fill($('#m-punto'), h.punto_reunion);
      $('#m-alert').classList.toggle('show', h.altura < 2100);
    });
    $('#m-altura').addEventListener('input', e => {
      $('#m-alert').classList.toggle('show', +e.target.value > 0 && +e.target.value < 2100);
    });

    const close = () => ov.remove();
    ov.querySelectorAll('[data-close]').forEach(b => b.addEventListener('click', close));
    ov.addEventListener('click', e => { if (e.target === ov) close(); });

    $('#m-save').addEventListener('click', () => {
      const idx = $('#m-huerta').value;
      const nombre = idx !== '' ? D.huertas[idx].huerta : 'nueva';
      const altura = +$('#m-altura').value || 0;
      const cuadrilla = $('#m-cuadrilla').value || 'Sin asignar';
      const grupo = altura > 0 && altura < 2100 ? 'alerta' : (cuadrilla === 'Sin asignar' ? 'pendiente' : 'confirmado');
      D.cortes.push({
        semana: week, grupo,
        huerta: 'Huerta ' + nombre,
        productor: $('#m-productor').value || '—',
        municipio: $('#m-municipio').value || '—',
        altura, empresa: cuadrilla, precio: null,
        vol: +$('#m-vol').value || 0, nuevo: true,
      });
      close();
      view = 'cortes';
      render();
    });
  }

  function soon() {
    return header('') + `<div class="soon"><div class="big">Próximamente</div><p>Esta vista se construye en la fase de Tesorería (ver <a href="plan.html">Gaps &amp; plan</a>).</p></div>`;
  }

  function center() {
    const pane = view === 'cortes' ? cortesPane()
      : view === 'cxp' ? cxpPane()
      : view === 'costeo' ? costeoPane()
      : view === 'catalogos' ? catalogosPane()
      : soon();
    return `<div class="app-center">${weekRow()}${kpiStrip()}${pane}</div>`;
  }

  function render() {
    root.innerHTML = side() + `<div class="app-body">${center()}</div>`;
    root.querySelectorAll('.nav-i').forEach(b => b.addEventListener('click', () => { view = b.dataset.v; render(); }));
    root.querySelectorAll('.app-wk').forEach(b => b.addEventListener('click', () => { week = +b.dataset.w; render(); }));
    root.querySelectorAll('[data-corte]').forEach(b => b.addEventListener('click', openCorteModal));
    const sel = root.querySelector('.role-sel');
    if (sel) sel.addEventListener('change', () => { roleIdx = sel.selectedIndex; render(); });
  }
  render();
}
