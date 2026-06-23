#!/usr/bin/env node
// Probar criterios amplios para ver cuántas filas devuelve cada uno.

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { execSync } from 'node:child_process'

chromiumExtra.use(StealthPlugin())

const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
const cred = notes.split('|').filter(Boolean)
  .map((c) => { const i = c.indexOf(':'); return { user: c.slice(0,i), pass: c.slice(i+1) } })
  .find((c) => c.user === 'adrian.acmargo')

const browser = await chromiumExtra.launch({ headless: true })
const ctx = await browser.newContext({
  viewport: { width: 1600, height: 1000 },
  locale: 'es-MX',
  userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
})
const page = await ctx.newPage()

await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'domcontentloaded' })
await page.waitForSelector('#ASPxTxtUsuario')
await page.waitForTimeout(1500)
await page.click('#ASPxTxtUsuario'); await page.type('#ASPxTxtUsuario', cred.user, { delay: 40 })
await page.click('#ASPxTxtContra'); await page.type('#ASPxTxtContra', cred.pass, { delay: 40 })
await Promise.all([page.waitForLoadState('networkidle').catch(()=>{}), page.click('#ASPxBtnIniciarSesion')])
await page.waitForTimeout(2500)

async function consultar(crit) {
  await page.goto('https://sicoa.senasica.gob.mx/SIC_ListadoGeneralDeHuertos.aspx', {
    waitUntil: 'domcontentloaded',
  })
  await page.waitForSelector('#SheetContentPlaceHolder_bConsultar')
  await page.addStyleTag({ content: '#wmContenedor{display:none !important;}' })
  await page.waitForTimeout(1500)
  await page.click('#SheetContentPlaceHolder_tbCriterio')
  await page.type('#SheetContentPlaceHolder_tbCriterio', crit, { delay: 40 })
  await page.click('#SheetContentPlaceHolder_bConsultar', { timeout: 120000 }).catch(()=>{})
  await page.waitForLoadState('domcontentloaded', { timeout: 120000 }).catch(()=>{})
  await page.waitForFunction(() => !document.body.innerText.includes('Loading…'), { timeout: 120000 }).catch(()=>{})
  await page.waitForTimeout(3000)

  return await page.evaluate(() => {
    let best = null, bestScore = 0
    for (const t of document.querySelectorAll('table')) {
      const headers = Array.from(t.querySelectorAll('tr')[0]?.children || []).map(c => c.textContent?.trim())
      const s = headers.filter(h => /huerta|sagarpa|status|localidad|municipio/i.test(h || '')).length
      if (s > bestScore) { bestScore = s; best = t }
    }
    if (!best) return { rows: 0, sample: null, municipios: {} }
    const rows = Array.from(best.querySelectorAll('tr')).slice(1)
      .map(tr => Array.from(tr.children).map(c => c.textContent?.trim()))
      .filter(r => r.length >= 5 && r.some(c => c?.length > 0))
    const sample = rows.slice(0, 3)
    const munIdx = 4
    const municipios = {}
    for (const r of rows) {
      const m = r[munIdx] || '?'
      municipios[m] = (municipios[m] || 0) + 1
    }
    return { rows: rows.length, sample, municipios }
  })
}

const CRITERIOS = ['A', 'E', 'I', 'O', 'U', 'TANCITARO', 'SALVADOR']
for (const c of CRITERIOS) {
  const r = await consultar(c)
  console.log(`\n"${c}": ${r.rows} filas`)
  if (r.rows > 0) {
    const mun = Object.entries(r.municipios).sort((a,b) => b[1]-a[1]).slice(0,5)
    console.log(`  Municipios top: ${mun.map(([m,n]) => `${m}(${n})`).join(', ')}`)
    if (r.sample[0]) console.log(`  Sample: ${r.sample[0].join(' | ')}`)
  }
}

await ctx.close()
await browser.close()
