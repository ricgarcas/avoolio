#!/usr/bin/env node
// Probe SIC_StatusHuertas + SIC_Result_MateriaSeca tras Consultar.

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

chromiumExtra.use(StealthPlugin())
const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'status-materia-' + new Date().toISOString().replace(/[:.]/g, '-'))
await mkdir(OUT, { recursive: true })

const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
const cred = notes.split('|').filter(Boolean)
  .map((c) => { const i = c.indexOf(':'); return { user: c.slice(0,i), pass: c.slice(i+1) } })
  .find((c) => c.user === 'RO.LEMO')

const browser = await chromiumExtra.launch({ headless: true })
const ctx = await browser.newContext({
  viewport: { width: 1600, height: 1200 },
  locale: 'es-MX',
  userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
})
const page = await ctx.newPage()

console.log('→ Login')
await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'domcontentloaded', timeout: 60000 })
await page.waitForTimeout(6000)
await page.click('#ASPxTxtUsuario'); await page.type('#ASPxTxtUsuario', cred.user, { delay: 80 })
await page.waitForTimeout(600)
await page.click('#ASPxTxtContra'); await page.type('#ASPxTxtContra', cred.pass, { delay: 80 })
await page.click('#ASPxBtnIniciarSesion')
await page.waitForLoadState('domcontentloaded').catch(()=>{})
await page.waitForTimeout(5000)

const REPORTES = [
  { url: 'SIC_StatusHuertas.aspx', btn: 'SheetContentPlaceHolder_bConsultarStatus' },
  { url: 'SIC_Result_MateriaSeca.aspx', btn: null }, // ya veremos
]

for (const { url, btn } of REPORTES) {
  console.log(`\n→ ${url}`)
  try {
    await page.waitForTimeout(4000)
    await page.goto(`https://sicoa.senasica.gob.mx/${url}`, { waitUntil: 'domcontentloaded', timeout: 60000 })
    await page.waitForTimeout(5000)
    await page.addStyleTag({ content: '#wmContenedor{display:none !important;}' }).catch(()=>{})
    const slug = url.replace('.aspx','')

    // Encontrar botón Consultar si btn no se dio
    const consultarBtn = btn ?? await page.evaluate(() => {
      for (const i of document.querySelectorAll('input[type="submit"]')) {
        if (/consult/i.test(i.value || '') || /consult/i.test(i.id || '')) return i.id
      }
      return null
    })
    if (!consultarBtn) { console.log('  sin botón consultar visible'); continue }
    console.log(`  → click ${consultarBtn}`)
    await page.click(`#${consultarBtn}`)
    await page.waitForLoadState('domcontentloaded').catch(()=>{})
    await page.waitForFunction(() => !document.body.innerText.includes('Loading…'), { timeout: 60000 }).catch(()=>{})
    await page.waitForTimeout(5000)
    await page.screenshot({ path: join(OUT, `${slug}.png`), fullPage: true })
    await writeFile(join(OUT, `${slug}.html`), await page.content())

    const headers = await page.evaluate(() => {
      let best = []
      for (const t of document.querySelectorAll('table')) {
        const h = Array.from(t.querySelectorAll('tr')[0]?.children || []).map(c => c.textContent?.trim()).filter(Boolean)
        if (h.length > best.length) best = h
      }
      return best
    })
    console.log(`  Headers (${headers.length}): ${headers.join(' | ')}`)
    const productorish = headers.filter(h => /productor|propietario|titular|dueño|rfc|curp|persona|nombre.*camp/i.test(h))
    if (productorish.length) console.log(`  🎯 POSIBLE PRODUCTOR: ${productorish.join(', ')}`)
  } catch (e) {
    console.log(`  ERROR: ${e.message.slice(0,100)}`)
  }
}

await ctx.close()
await browser.close()
console.log(`\n✓ ${OUT}`)
