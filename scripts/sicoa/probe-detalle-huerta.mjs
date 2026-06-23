#!/usr/bin/env node
// ¿Hay detalle de huerta con productor? Probar:
//  1. Click sobre la clave SAGARPA en la grilla
//  2. Click sobre el nombre de la huerta
//  3. Inspeccionar onclick handlers de la grilla

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

chromiumExtra.use(StealthPlugin())
const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'detalle-' + new Date().toISOString().replace(/[:.]/g, '-'))
await mkdir(OUT, { recursive: true })

const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
const cred = notes.split('|').filter(Boolean)
  .map((c) => { const i = c.indexOf(':'); return { user: c.slice(0,i), pass: c.slice(i+1) } })
  .find((c) => c.user === 'LIXA.QUIROS')

const browser = await chromiumExtra.launch({ headless: true })
const ctx = await browser.newContext({
  recordHar: { path: join(OUT, 'session.har'), content: 'embed' },
  viewport: { width: 1600, height: 1200 },
  locale: 'es-MX',
  userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
})
const page = await ctx.newPage()
const reqLog = []
page.on('response', (r) => reqLog.push(`${r.status()} ${r.request().method()} ${r.url()}`))

console.log(`→ Login: ${cred.user}`)
await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'domcontentloaded' })
await page.waitForSelector('#ASPxTxtUsuario')
await page.waitForTimeout(1500)
await page.click('#ASPxTxtUsuario'); await page.type('#ASPxTxtUsuario', cred.user, { delay: 40 })
await page.click('#ASPxTxtContra'); await page.type('#ASPxTxtContra', cred.pass, { delay: 40 })
await Promise.all([page.waitForLoadState('networkidle').catch(()=>{}), page.click('#ASPxBtnIniciarSesion')])
await page.waitForTimeout(2500)

await page.goto('https://sicoa.senasica.gob.mx/SIC_ListadoGeneralDeHuertos.aspx', {
  waitUntil: 'domcontentloaded',
})
await page.waitForSelector('#SheetContentPlaceHolder_bConsultar')
await page.addStyleTag({ content: '#wmContenedor{display:none !important;}' })
await page.waitForTimeout(1500)
await page.click('#SheetContentPlaceHolder_tbCriterio')
await page.type('#SheetContentPlaceHolder_tbCriterio', 'PATZCUARO', { delay: 40 })
await page.click('#SheetContentPlaceHolder_bConsultar')
await page.waitForLoadState('domcontentloaded').catch(()=>{})
await page.waitForFunction(() => !document.body.innerText.includes('Loading…'), { timeout: 60000 }).catch(()=>{})
await page.waitForTimeout(2500)

await page.screenshot({ path: join(OUT, '01-grid.png'), fullPage: true })

// Inspeccionar la fila de datos
const rowInfo = await page.evaluate(() => {
  const tables = Array.from(document.querySelectorAll('table'))
  // Encontrar la grilla
  let grid = null
  for (const t of tables) {
    const headers = Array.from(t.querySelectorAll('tr')[0]?.children || []).map(c => c.textContent?.trim())
    if (headers.some(h => /sagarpa/i.test(h || ''))) { grid = t; break }
  }
  if (!grid) return null
  const dataRow = grid.querySelectorAll('tr')[1]
  if (!dataRow) return null

  // Inspeccionar cada celda: si tiene onclick, link, etc.
  const cells = Array.from(dataRow.children).map((c, idx) => ({
    idx,
    text: c.textContent?.trim().slice(0, 60),
    onclick: c.getAttribute('onclick') || null,
    innerHTML: c.innerHTML.slice(0, 300),
    hasAnchor: !!c.querySelector('a'),
    anchorHref: c.querySelector('a')?.getAttribute('href') || null,
  }))
  return { gridId: grid.id, cells }
})
await writeFile(join(OUT, 'row-inspect.json'), JSON.stringify(rowInfo, null, 2))
console.log(JSON.stringify(rowInfo, null, 2).slice(0, 2000))

// Intentar doble click sobre fila
console.log('\n→ Doble click sobre primera fila')
const firstRow = await page.$('table tr:nth-child(2) td')
if (firstRow) {
  await firstRow.dblclick({ timeout: 5000 }).catch((e) => console.log(' dblclick error:', e.message.slice(0,80)))
  await page.waitForTimeout(2500)
  await page.screenshot({ path: join(OUT, '02-dblclick.png'), fullPage: true })
}

// Probar select row + revisar si surge panel
const beforeUrl = page.url()
await page.click('table tr:nth-child(2)', { timeout: 5000 }).catch(()=>{})
await page.waitForTimeout(1500)
const afterUrl = page.url()
console.log(`URL before/after click: ${beforeUrl} → ${afterUrl}`)
await page.screenshot({ path: join(OUT, '03-rowclick.png'), fullPage: true })

await writeFile(join(OUT, 'requests.log'), reqLog.join('\n'))
await ctx.close()
await browser.close()
console.log(`\n✓ ${OUT}`)
