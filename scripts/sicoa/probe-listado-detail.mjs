#!/usr/bin/env node
// Fase 4 spec: investigar comportamiento real del Listado General de Huertos.
//   - ¿Consultar con criterio vacío trae todo?
//   - ¿Pagina? ¿Cuántas páginas?
//   - ¿Qué columnas tiene la grilla?
//   - Sample row para diseñar schema

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

chromiumExtra.use(StealthPlugin())
const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'detail-' + new Date().toISOString().replace(/[:.]/g, '-'))
await mkdir(OUT, { recursive: true })

const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
const cred = notes.split('|').filter(Boolean)
  .map((c) => { const i = c.indexOf(':'); return { user: c.slice(0,i), pass: c.slice(i+1) } })
  .find((c) => c.user === 'adrian.acmargo')

const browser = await chromiumExtra.launch({ headless: true })
const ctx = await browser.newContext({
  recordHar: { path: join(OUT, 'session.har'), content: 'embed' },
  viewport: { width: 1600, height: 1000 },
  locale: 'es-MX',
  userAgent:
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
})
const page = await ctx.newPage()

console.log(`→ Login: ${cred.user}`)
await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'domcontentloaded' })
await page.waitForSelector('#ASPxTxtUsuario')
await page.waitForTimeout(1500)
await page.click('#ASPxTxtUsuario'); await page.type('#ASPxTxtUsuario', cred.user, { delay: 40 })
await page.click('#ASPxTxtContra');  await page.type('#ASPxTxtContra', cred.pass, { delay: 40 })
await Promise.all([page.waitForLoadState('networkidle').catch(()=>{}), page.click('#ASPxBtnIniciarSesion')])
await page.waitForTimeout(2500)

console.log('\n→ Listado General de Huertos')
await page.goto('https://sicoa.senasica.gob.mx/SIC_ListadoGeneralDeHuertos.aspx', {
  waitUntil: 'domcontentloaded',
})
await page.waitForTimeout(2000)
await page.screenshot({ path: join(OUT, '01-form.png'), fullPage: true })

// Capturar inputs del formulario para entender qué postear
const formFields = await page.$$eval('input, select', (els) =>
  els.map((e) => ({
    tag: e.tagName,
    name: e.name,
    id: e.id,
    type: e.type,
    value: e.value?.slice(0, 80),
    options: e.tagName === 'SELECT' ? Array.from(e.options).map((o) => o.value) : null,
  }))
)
await writeFile(join(OUT, 'form-fields.json'), JSON.stringify(formFields, null, 2))
const estadoSelect = formFields.find((f) => f.tag === 'SELECT' && /estado/i.test(f.name + f.id))
console.log(`  Estado select: ${estadoSelect?.id} con ${estadoSelect?.options?.length} opciones`)
console.log(`  Estados disponibles: ${estadoSelect?.options?.join(', ')}`)

// Localizar el botón Consultar y el textbox criterio
const consultarBtn = formFields.find((f) => /consultar|btn/i.test(f.id || '') && f.type === 'submit')
const criterioTxt = formFields.find((f) => /criterio|busqueda|txt/i.test(f.id || '') && f.type === 'text')
console.log(`  Botón Consultar: ${consultarBtn?.id}`)
console.log(`  Textbox criterio: ${criterioTxt?.id}`)

console.log('\n→ Click Consultar con criterio vacío…')
if (!consultarBtn?.id) {
  console.error('  No encontré botón Consultar — abortando')
  await page.screenshot({ path: join(OUT, '99-no-button.png'), fullPage: true })
} else {
  // Asegurar que estado = MICHOACAN
  if (estadoSelect?.id) {
    await page.selectOption(`#${estadoSelect.id}`, { label: 'MICHOACAN' }).catch(() => {})
  }
  await Promise.all([
    page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => {}),
    page.click(`#${consultarBtn.id}`),
  ])
  await page.waitForTimeout(4000)
  await page.screenshot({ path: join(OUT, '02-results.png'), fullPage: true })
  await writeFile(join(OUT, '02-results.html'), await page.content())

  // Analizar tablas y paginación
  const grids = await page.$$eval('table', (els) => els.map((t, idx) => {
    const headers = Array.from(t.querySelectorAll('thead th, tr:first-child th, tr:first-child td')).map((c) => c.textContent?.trim())
    const rows = t.querySelectorAll('tr').length
    return { idx, rows, headers: headers.slice(0, 30) }
  }))
  const dataGrids = grids.filter((g) => g.rows > 5)
  console.log(`\n  Tablas con datos: ${dataGrids.length}`)
  dataGrids.forEach((g) => console.log(`    idx=${g.idx} rows=${g.rows} headers=${g.headers.filter(Boolean).slice(0,8).join(' | ')}`))
  await writeFile(join(OUT, 'grids.json'), JSON.stringify(grids, null, 2))

  // Buscar pager DevExpress
  const pager = await page.$$eval(
    '[id*="Pager"], [class*="pager"], [id*="PageBar"], [class*="dxpPageBar"]',
    (els) => els.map((e) => ({ id: e.id, cls: e.className, text: e.textContent?.trim().slice(0, 200) }))
  )
  await writeFile(join(OUT, 'pager.json'), JSON.stringify(pager, null, 2))
  console.log(`\n  Elementos de paginación: ${pager.length}`)
  pager.slice(0, 5).forEach((p) => console.log(`    ${p.id || p.cls}: ${p.text?.slice(0,80)}`))

  // Extraer primera fila como muestra
  const sampleRow = await page.evaluate(() => {
    const tables = document.querySelectorAll('table')
    for (const t of tables) {
      const rows = t.querySelectorAll('tr')
      if (rows.length < 5) continue
      const headerCells = Array.from(rows[0].querySelectorAll('th, td')).map((c) => c.textContent?.trim())
      const firstDataRow = Array.from(rows[1].querySelectorAll('td')).map((c) => c.textContent?.trim())
      return { headers: headerCells, sample: firstDataRow }
    }
    return null
  })
  await writeFile(join(OUT, 'sample-row.json'), JSON.stringify(sampleRow, null, 2))
  console.log('\n  Sample row:')
  if (sampleRow) {
    sampleRow.headers.forEach((h, i) => console.log(`    ${h?.padEnd(30)} → ${sampleRow.sample[i]?.slice(0, 60)}`))
  }
}

await ctx.close()
await browser.close()
console.log(`\n✓ ${OUT}`)
