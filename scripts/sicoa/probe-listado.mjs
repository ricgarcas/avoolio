#!/usr/bin/env node
import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

chromiumExtra.use(StealthPlugin())
const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'listado-' + new Date().toISOString().replace(/[:.]/g, '-'))
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

await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'domcontentloaded' })
await page.waitForSelector('#ASPxTxtUsuario')
await page.waitForTimeout(1500)
await page.click('#ASPxTxtUsuario'); await page.type('#ASPxTxtUsuario', cred.user, { delay: 40 })
await page.click('#ASPxTxtContra');  await page.type('#ASPxTxtContra', cred.pass, { delay: 40 })
await Promise.all([page.waitForLoadState('networkidle').catch(()=>{}), page.click('#ASPxBtnIniciarSesion')])
await page.waitForTimeout(2500)

const PAGES = [
  'SIC_ListadoGeneralDeHuertos.aspx',
  'SIC_CortesProgramados.aspx',
  'SIC_HuertosLimpiosV2.aspx',
  'SIC_StatusHuertas.aspx',
  'SIC_Result_MateriaSeca.aspx',
]

for (const p of PAGES) {
  try {
    console.log(`\n→ ${p}`)
    await page.goto(`https://sicoa.senasica.gob.mx/${p}`, { waitUntil: 'domcontentloaded', timeout: 30000 })
    await page.waitForTimeout(3000)
    const slug = p.replace('.aspx', '')
    await page.screenshot({ path: join(OUT, `${slug}.png`), fullPage: true })
    await writeFile(join(OUT, `${slug}.html`), await page.content())

    // Buscar botones de export
    const exportBtns = await page.$$eval('input[type="submit"], input[type="button"], button, a', (els) =>
      els
        .map((e) => ({ text: (e.value || e.textContent || '').trim().slice(0, 50), id: e.id, name: e.name, href: e.getAttribute?.('href') }))
        .filter((b) => b.text && /excel|csv|export|exportar|pdf|descargar/i.test(b.text))
    )
    console.log(`   Export buttons: ${exportBtns.length}`)
    exportBtns.forEach((b) => console.log(`     - ${b.text} (id=${b.id})`))

    // Contar filas de la primera tabla
    const tables = await page.$$eval('table', (els) => els.map((t) => ({
      rows: t.querySelectorAll('tr').length,
      cells: t.querySelectorAll('th, td').length,
    })))
    const big = tables.filter((t) => t.rows > 3).slice(0, 5)
    console.log(`   Tablas con datos: ${big.map((t) => t.rows + 'r').join(', ')}`)
  } catch (e) {
    console.log(`   ERROR: ${e.message.slice(0,80)}`)
  }
}

await writeFile(join(OUT, 'requests.log'), reqLog.join('\n'))
await ctx.close()
await browser.close()
console.log(`\n✓ ${OUT}`)
