#!/usr/bin/env node
// Expandir filas y probar criterio grande (URUAPAN).

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

chromiumExtra.use(StealthPlugin())
const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'expand-' + new Date().toISOString().replace(/[:.]/g, '-'))
await mkdir(OUT, { recursive: true })

const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
const cred = notes.split('|').filter(Boolean)
  .map((c) => { const i = c.indexOf(':'); return { user: c.slice(0,i), pass: c.slice(i+1) } })
  .find((c) => c.user === 'adrian.acmargo')

const browser = await chromiumExtra.launch({ headless: true })
const ctx = await browser.newContext({
  viewport: { width: 1600, height: 1200 },
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

async function consulta(crit) {
  console.log(`\n=== "${crit}" ===`)
  await page.goto('https://sicoa.senasica.gob.mx/SIC_ListadoGeneralDeHuertos.aspx', {
    waitUntil: 'domcontentloaded',
  })
  await page.waitForSelector('#SheetContentPlaceHolder_bConsultar')
  await page.waitForTimeout(1500)
  await page.click('#SheetContentPlaceHolder_tbCriterio')
  await page.type('#SheetContentPlaceHolder_tbCriterio', crit, { delay: 40 })
  await Promise.all([
    page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => {}),
    page.click('#SheetContentPlaceHolder_bConsultar'),
  ])
  await page.waitForFunction(() => !document.body.innerText.includes('Loading…'), { timeout: 30000 }).catch(()=>{})
  await page.waitForTimeout(2000)
}

// Extraer todas las filas + headers correctamente
async function snapshot(crit) {
  const data = await page.evaluate(() => {
    // GridView principal — buscar tabla más grande con headers reconocibles
    const tables = Array.from(document.querySelectorAll('table'))
    let best = null
    let bestScore = 0
    for (const t of tables) {
      const headers = Array.from(t.querySelectorAll('tr')[0]?.children || []).map((c) => c.textContent?.trim())
      const score = headers.filter((h) => /huerta|sagarpa|status|localidad|municipio/i.test(h || '')).length
      if (score > bestScore) { bestScore = score; best = t }
    }
    if (!best) return { headers: [], rows: [], pager: null }
    const allRows = Array.from(best.querySelectorAll('tr'))
    const headers = Array.from(allRows[0].children).map((c) => c.textContent?.trim())
    const dataRows = allRows.slice(1).map((tr) =>
      Array.from(tr.children).map((c) => c.textContent?.trim())
    ).filter((r) => r.some((c) => c && c.length > 0))
    // Pager bar
    const pager = document.querySelector('[id*="PageBar"], [id*="Pager"], [id$="_DXPager"]')?.textContent?.trim()
    return { headers, rows: dataRows, pager, tableId: best.id }
  })
  return data
}

const criterios = ['PATZCUARO', 'URUAPAN', 'TINGAMBATO']
const allResults = {}
for (const crit of criterios) {
  await consulta(crit)
  const slug = crit.toLowerCase()
  await page.screenshot({ path: join(OUT, `${slug}.png`), fullPage: true })
  await writeFile(join(OUT, `${slug}.html`), await page.content())
  const data = await snapshot(crit)
  console.log(`  Headers: ${data.headers.filter(Boolean).join(' | ')}`)
  console.log(`  Rows: ${data.rows.length}`)
  console.log(`  Pager: ${data.pager || '(sin pager)'}`)
  if (data.rows[0]) console.log(`  Row[0]: ${data.rows[0].join(' | ')}`)
  await writeFile(join(OUT, `${slug}.json`), JSON.stringify(data, null, 2))
  allResults[crit] = data
}

// Para PATZCUARO, intentar expandir el "+"
console.log('\n=== Expand row PATZCUARO ===')
await consulta('PATZCUARO')
const expandBtns = await page.$$('img[src*="expand"], [class*="dxGridView_gvDetailCollapsedButton"], [onclick*="DetailRow"]')
console.log(`  Botones expand candidatos: ${expandBtns.length}`)
// Más amplio: cualquier elemento clickeable que tenga "+" como texto o un id que sugiera expand
const allClick = await page.$$eval('img, td, span', (els) =>
  els
    .filter((e) => {
      const id = e.id || ''
      const cls = e.className || ''
      return /[Ee]xpand|[Dd]etail/.test(id + cls) || e.textContent?.trim() === '+'
    })
    .map((e) => ({ tag: e.tagName, id: e.id, cls: e.className, text: e.textContent?.trim().slice(0,30) }))
    .slice(0, 30)
)
console.log('  Candidatos:', JSON.stringify(allClick, null, 2))
await writeFile(join(OUT, 'expand-candidates.json'), JSON.stringify(allClick, null, 2))

// Intentar clickear el primer botón con "Expand" en class/id
const exp = await page.$('[id*="Expand"], img[class*="Expand"], [class*="dxGridView_gvDetailCollapsedButton_"]')
if (exp) {
  console.log('  → Clickeando expand…')
  await exp.click()
  await page.waitForTimeout(2500)
  await page.screenshot({ path: join(OUT, 'patzcuaro-expanded.png'), fullPage: true })
  await writeFile(join(OUT, 'patzcuaro-expanded.html'), await page.content())
}

await ctx.close()
await browser.close()
console.log(`\n✓ ${OUT}`)
