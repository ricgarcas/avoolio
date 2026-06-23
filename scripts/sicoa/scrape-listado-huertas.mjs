#!/usr/bin/env node
// Scraper SICOA — Listado General de Huertos.
// Estrategia de barrido por capas de criterios (ver criterios.json):
//   1. municipios (28+)
//   2. apellidos de productores
//   3. nombres de productores
//   4. términos comunes en nombres de huertas
//   5. localidades pequeñas
//
// Resilience:
//   - re-login automático si la sesión expira a media corrida
//   - dedupe en memoria por clave_sagarpa (1 insert por huerta nueva)
//   - jitter aleatorio entre queries (1-3s) para no parecer bot bursty
//   - skip silencioso de criterios que devuelven 0 (común para palabras raras)
//   - log de progreso en stdout y en sicoa_raw.scrape_log
//
// Uso:
//   node scripts/sicoa/scrape-listado-huertas.mjs                    # default: todas las capas
//   SICOA_CAPAS=municipios node scripts/sicoa/scrape-listado-huertas.mjs
//   SICOA_CRITERIOS="X,Y,Z" node scripts/sicoa/scrape-listado-huertas.mjs

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { execSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import pg from 'pg'

chromiumExtra.use(StealthPlugin())

const HERE = dirname(fileURLToPath(import.meta.url))
const SCRAPER = 'listado-huertas'
const VERSION = '0.3.0'
const DB_URL = process.env.DB_URL || 'postgres://root@127.0.0.1:5432/avoolio'

// ─── criterios ────────────────────────────────────────────────────────────────

const CRITERIOS_FILE = JSON.parse(readFileSync(join(HERE, 'criterios.json'), 'utf8'))
const CAPA_KEYS = [
  'municipios', 'productor_apellidos', 'productor_nombres',
  'huerta_terminos', 'geo_localidades_aguacate_mich',
]

function buildCriterios() {
  if (process.env.SICOA_CRITERIOS) {
    return process.env.SICOA_CRITERIOS.split(',').map((s) => s.trim()).filter(Boolean)
  }
  const capas = process.env.SICOA_CAPAS
    ? process.env.SICOA_CAPAS.split(',').map((s) => s.trim())
    : CAPA_KEYS
  const seen = new Set()
  const out = []
  for (const capa of capas) {
    for (const c of CRITERIOS_FILE[capa] || []) {
      const k = c.toUpperCase().trim()
      if (seen.has(k)) continue
      seen.add(k)
      out.push(c)
    }
  }
  return out
}

// ─── credenciales ─────────────────────────────────────────────────────────────

function pickCred() {
  if (process.env.SICOA_USER && process.env.SICOA_PASS) {
    return { user: process.env.SICOA_USER, pass: process.env.SICOA_PASS }
  }
  const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
  const all = notes.split('|').filter(Boolean).map((c) => {
    const i = c.indexOf(':')
    return { user: c.slice(0, i), pass: c.slice(i + 1) }
  })
  const live = new Set(['adrian.acmargo', 'Laga.Le', 'RO.LEMO', 'LIXA.QUIROS'])
  const pool = all.filter((c) => live.has(c.user))
  return pool[Math.floor(Date.now() / 60000) % pool.length] || pool[0]
}

// ─── navegación SICOA ─────────────────────────────────────────────────────────

async function login(page, cred) {
  await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'domcontentloaded', timeout: 30000 })
  await page.waitForSelector('#ASPxTxtUsuario', { timeout: 15000 })
  await page.waitForTimeout(1500)
  await page.click('#ASPxTxtUsuario')
  await page.type('#ASPxTxtUsuario', cred.user, { delay: 50 })
  await page.click('#ASPxTxtContra')
  await page.type('#ASPxTxtContra', cred.pass, { delay: 50 })
  await page.click('#ASPxBtnIniciarSesion', { timeout: 30000 })
  await page.waitForLoadState('domcontentloaded', { timeout: 30000 }).catch(() => {})
  await page.waitForTimeout(2500)
  const html = await page.content()
  if (html.includes('Contraseña incorrecta') || html.includes('ASPxTxtContra')) {
    throw new Error(`Login falló con ${cred.user}`)
  }
}

async function isLoggedIn(page) {
  // Si después de navegar al reporte aún hay form de login, no estamos logueados
  try {
    await page.goto('https://sicoa.senasica.gob.mx/SIC_ListadoGeneralDeHuertos.aspx', {
      waitUntil: 'domcontentloaded',
      timeout: 30000,
    })
    await page.waitForTimeout(1500)
    const html = await page.content()
    return !html.includes('ASPxTxtContra')
  } catch {
    return false
  }
}

async function consultar(page, criterio) {
  await page.goto('https://sicoa.senasica.gob.mx/SIC_ListadoGeneralDeHuertos.aspx', {
    waitUntil: 'domcontentloaded',
    timeout: 30000,
  })
  await page.waitForSelector('#SheetContentPlaceHolder_bConsultar', { timeout: 15000 })
  await page.addStyleTag({ content: '#wmContenedor{display:none !important;}' })
  await page.waitForTimeout(1500)
  await page.click('#SheetContentPlaceHolder_tbCriterio')
  await page.type('#SheetContentPlaceHolder_tbCriterio', criterio, { delay: 30 })
  await page.click('#SheetContentPlaceHolder_bConsultar', { timeout: 60000 })
  await page.waitForLoadState('domcontentloaded', { timeout: 120000 }).catch(() => {})
  await page.waitForFunction(() => !document.body.innerText.includes('Loading…'), {
    timeout: 180000,
  }).catch(() => {})
  await page.waitForTimeout(2000)

  return await page.evaluate(() => {
    let best = null
    let bestScore = 0
    for (const t of document.querySelectorAll('table')) {
      const headers = Array.from(t.querySelectorAll('tr')[0]?.children || []).map((c) => c.textContent?.trim())
      const score = headers.filter((h) => /huerta|sagarpa|status|localidad|municipio/i.test(h || '')).length
      if (score > bestScore) { bestScore = score; best = t }
    }
    if (!best) return { headers: [], rows: [] }
    const all = Array.from(best.querySelectorAll('tr'))
    const headers = Array.from(all[0].children).map((c) => c.textContent?.trim())
    const rows = all.slice(1)
      .map((tr) => Array.from(tr.children).map((c) => c.textContent?.trim()))
      .filter((r) => r.length === headers.length && r.some((c) => c && c.length > 0))
    return { headers, rows }
  })
}

function toRecord(headers, row, { estado, criterio }) {
  const get = (label) => {
    const i = headers.findIndex((h) => new RegExp(label, 'i').test(h || ''))
    return i >= 0 ? row[i] : null
  }
  const rec = {
    estado, criterio,
    nombre_huerta: get('huerta'),
    clave_sagarpa: get('sagarpa'),
    status: get('status'),
    localidad: get('localidad'),
    municipio: get('municipio'),
  }
  rec.payload = headers.reduce((acc, h, i) => { acc[h] = row[i]; return acc }, {})
  return rec
}

const jitter = () => new Promise((r) => setTimeout(r, 1000 + Math.random() * 2000))

// ─── main ─────────────────────────────────────────────────────────────────────

async function main() {
  const criterios = buildCriterios()
  if (!criterios.length) throw new Error('Sin criterios')
  const cred = pickCred()
  if (!cred) throw new Error('Sin credenciales vivas en op://Personal/SICOA')

  console.log(`▶ Capas: ${process.env.SICOA_CAPAS || CAPA_KEYS.join(',')}`)
  console.log(`▶ Total criterios: ${criterios.length}`)
  console.log(`▶ Cred inicial: ${cred.user}`)

  const db = new pg.Client({ connectionString: DB_URL })
  await db.connect()

  const { rows: [{ id: logId }] } = await db.query(
    `insert into sicoa_raw.scrape_log (scraper, scraper_version, cred_user, criterios)
     values ($1, $2, $3, $4) returning id`,
    [SCRAPER, VERSION, cred.user, criterios],
  )
  console.log(`▶ scrape_log id=${logId}`)

  const browser = await chromiumExtra.launch({ headless: true })
  const ctx = await browser.newContext({
    viewport: { width: 1600, height: 1000 },
    locale: 'es-MX',
    userAgent:
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  })
  const page = await ctx.newPage()

  let totalInserted = 0
  const seen = new Set()
  const fetchedAt = new Date()
  let currentCred = cred

  try {
    console.log(`  → login`)
    await login(page, currentCred)

    for (let i = 0; i < criterios.length; i++) {
      const criterio = criterios[i]
      const prefix = `  [${String(i + 1).padStart(3, ' ')}/${criterios.length}] ${criterio}`
      try {
        const { headers, rows } = await consultar(page, criterio)
        const valid = rows.map((r) => toRecord(headers, r, { estado: 'MICHOACAN', criterio }))
          .filter((r) => r.clave_sagarpa && r.nombre_huerta)

        let newCount = 0
        for (const r of valid) {
          if (seen.has(r.clave_sagarpa)) continue
          seen.add(r.clave_sagarpa)
          await db.query(
            `insert into sicoa_raw.huerta_listado_general
               (fetched_at, estado, criterio, clave_sagarpa, nombre_huerta, status,
                localidad, municipio, payload, scraper_version, cred_user)
             values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
             on conflict (clave_sagarpa, fetched_at) do nothing`,
            [fetchedAt, r.estado, r.criterio, r.clave_sagarpa, r.nombre_huerta, r.status,
              r.localidad, r.municipio, r.payload, VERSION, currentCred.user],
          )
          newCount += 1
          totalInserted += 1
        }
        console.log(`${prefix}: ${rows.length} hits, +${newCount} nuevas (total únicas: ${seen.size})`)
      } catch (e) {
        const msg = e.message.slice(0, 200)
        console.log(`${prefix}: ✗ ${msg}`)
        // ¿sesión expirada? Reintentar login y este criterio
        if (!(await isLoggedIn(page))) {
          console.log(`     ↺ sesión perdida, re-login`)
          try {
            await login(page, currentCred)
          } catch {
            currentCred = pickCred()
            console.log(`     ↺ cred nueva: ${currentCred.user}`)
            await login(page, currentCred)
          }
          i -= 1 // reintentar el mismo criterio
        }
      }
      await jitter()
    }

    await db.query(
      `update sicoa_raw.scrape_log
         set finished_at = now(), status = 'ok', rows_inserted = $2
         where id = $1`,
      [logId, totalInserted],
    )
    console.log(`\n✓ ${totalInserted} filas únicas insertadas (de ${criterios.length} criterios)`)
  } catch (e) {
    console.error(`\n✗ ${e.message}`)
    await db.query(
      `update sicoa_raw.scrape_log
         set finished_at = now(), status = 'error', rows_inserted = $2, error_message = $3
         where id = $1`,
      [logId, totalInserted, e.message.slice(0, 500)],
    )
    process.exitCode = 1
  } finally {
    await ctx.close()
    await browser.close()
    await db.end()
  }
}

main().catch((e) => { console.error(e); process.exit(2) })
