#!/usr/bin/env node
// Probar Consultar con distintos criterios para ver qué devuelve el server.

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

chromiumExtra.use(StealthPlugin())
const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'consulta-' + new Date().toISOString().replace(/[:.]/g, '-'))
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
const reqLog = []
page.on('response', (r) => reqLog.push(`${r.status()} ${r.request().method()} ${r.url()}`))

console.log(`→ Login: ${cred.user}`)
await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'domcontentloaded' })
await page.waitForSelector('#ASPxTxtUsuario')
await page.waitForTimeout(1500)
await page.click('#ASPxTxtUsuario'); await page.type('#ASPxTxtUsuario', cred.user, { delay: 40 })
await page.click('#ASPxTxtContra');  await page.type('#ASPxTxtContra', cred.pass, { delay: 40 })
await Promise.all([page.waitForLoadState('networkidle').catch(()=>{}), page.click('#ASPxBtnIniciarSesion')])
await page.waitForTimeout(2500)

const CRITERIOS = ['', 'PATZCUARO', 'A', '16']

for (const crit of CRITERIOS) {
  const label = crit || 'EMPTY'
  console.log(`\n=== Criterio: "${label}" ===`)
  await page.goto('https://sicoa.senasica.gob.mx/SIC_ListadoGeneralDeHuertos.aspx', {
    waitUntil: 'domcontentloaded',
  })
  await page.waitForSelector('#SheetContentPlaceHolder_bConsultar', { timeout: 15000 })
  await page.waitForTimeout(1500)

  if (crit) {
    await page.click('#SheetContentPlaceHolder_tbCriterio')
    await page.type('#SheetContentPlaceHolder_tbCriterio', crit, { delay: 50 })
  }
  await Promise.all([
    page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => {}),
    page.click('#SheetContentPlaceHolder_bConsultar'),
  ])
  // Esperar a que desaparezca Loading…
  await page.waitForFunction(() => !document.body.innerText.includes('Loading…'), { timeout: 30000 }).catch(() => {})
  await page.waitForTimeout(2000)

  const slug = `crit-${label.replace(/[^a-z0-9]+/gi,'_').slice(0,20)}`
  await page.screenshot({ path: join(OUT, `${slug}.png`), fullPage: true })

  // Contar filas reales + headers
  const result = await page.evaluate(() => {
    const grids = []
    for (const t of document.querySelectorAll('table')) {
      const rows = t.querySelectorAll('tr')
      if (rows.length < 3) continue
      const id = t.id || t.closest('[id]')?.id || ''
      const headers = Array.from(rows[0].querySelectorAll('th, td')).map((c) => c.textContent?.trim())
      const dataRows = []
      for (let i = 1; i < Math.min(rows.length, 4); i++) {
        dataRows.push(Array.from(rows[i].querySelectorAll('td')).map((c) => c.textContent?.trim().slice(0,60)))
      }
      grids.push({ id, rows: rows.length, headers, sampleRows: dataRows })
    }
    const pageInfo = document.querySelector('[id*="PageBar"], [id*="Pager"]')?.textContent?.trim() || null
    return { grids, pageInfo, bodyHasNoData: document.body.innerText.includes('No data') || document.body.innerText.includes('Sin registros') }
  })
  await writeFile(join(OUT, `${slug}.json`), JSON.stringify(result, null, 2))

  const bigGrids = result.grids.filter((g) => g.rows > 5 && g.headers.filter(Boolean).length > 3)
  console.log(`  Tablas con datos: ${bigGrids.length}`)
  bigGrids.forEach((g) => {
    console.log(`    ${g.id} rows=${g.rows}`)
    console.log(`    Headers: ${g.headers.filter(Boolean).slice(0,10).join(' | ')}`)
    if (g.sampleRows[0]) console.log(`    Sample:  ${g.sampleRows[0].slice(0,10).join(' | ')}`)
  })
  if (result.pageInfo) console.log(`  Paginación: ${result.pageInfo}`)
  if (result.bodyHasNoData) console.log(`  ⚠ Mensaje "sin registros"`)
}

await writeFile(join(OUT, 'requests.log'), reqLog.join('\n'))
await ctx.close()
await browser.close()
console.log(`\n✓ ${OUT}`)
