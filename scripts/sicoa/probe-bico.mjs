#!/usr/bin/env node
// Explorar el reporte BICO para ver si trae productor / dueño / RFC

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

chromiumExtra.use(StealthPlugin())
const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'bico-' + new Date().toISOString().replace(/[:.]/g, '-'))
await mkdir(OUT, { recursive: true })

const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
const all = notes.split('|').filter(Boolean)
  .map((c) => { const i = c.indexOf(':'); return { user: c.slice(0,i), pass: c.slice(i+1) } })

// Rotar cred: usar la que NO usamos en el scrape grande
const cred = all.find((c) => c.user === 'Laga.Le')

const browser = await chromiumExtra.launch({ headless: true })
const ctx = await browser.newContext({
  recordHar: { path: join(OUT, 'session.har'), content: 'embed' },
  viewport: { width: 1600, height: 1200 },
  locale: 'es-MX',
  userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
})
const page = await ctx.newPage()

console.log(`→ Login: ${cred.user}`)
await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'domcontentloaded', timeout: 60000 })
await page.waitForSelector('#ASPxTxtUsuario', { timeout: 30000 })
await page.waitForTimeout(2000)
await page.click('#ASPxTxtUsuario'); await page.type('#ASPxTxtUsuario', cred.user, { delay: 50 })
await page.click('#ASPxTxtContra'); await page.type('#ASPxTxtContra', cred.pass, { delay: 50 })
await page.click('#ASPxBtnIniciarSesion')
await page.waitForLoadState('domcontentloaded').catch(()=>{})
await page.waitForTimeout(3500)

const REPORTES = [
  'DetallesGeograficosDeEmisionDelBICO.aspx',
  'SIC_StatusHuertas.aspx',
  'SIC_Result_MateriaSeca.aspx',
]

for (const url of REPORTES) {
  console.log(`\n→ ${url}`)
  try {
    await page.goto(`https://sicoa.senasica.gob.mx/${url}`, {
      waitUntil: 'domcontentloaded', timeout: 30000,
    })
    await page.waitForTimeout(2500)
    await page.addStyleTag({ content: '#wmContenedor{display:none !important;}' })
    const slug = url.replace('.aspx','')
    await page.screenshot({ path: join(OUT, `${slug}-form.png`), fullPage: true })
    await writeFile(join(OUT, `${slug}-form.html`), await page.content())

    // ¿Hay form fields? Listar.
    const fields = await page.$$eval('input, select, textarea', (els) =>
      els.filter(e => e.id || e.name).map(e => ({
        tag: e.tagName, type: e.type, id: e.id, name: e.name,
        placeholder: e.placeholder?.slice(0,40), label: e.labels?.[0]?.textContent?.trim().slice(0,40),
      }))
    )
    const interesting = fields.filter(f => /criterio|busqueda|estado|consultar|huerta|clave|productor|sagarpa/i.test(`${f.id} ${f.name} ${f.label||''} ${f.placeholder||''}`))
    console.log(`  Form fields relevantes: ${interesting.length}`)
    interesting.forEach(f => console.log(`    ${f.tag}/${f.type} id=${f.id} name=${f.name} ${f.placeholder?'ph=\"'+f.placeholder+'\"':''}`))

    // Si hay botón consultar y campo criterio, probar con PATZCUARO
    const consultarBtn = fields.find(f => /consultar|btn/i.test(f.id||'') && f.type==='submit')
    const criterioTxt = fields.find(f => /criterio|busqueda|txt|claveSagarpa|sagarpa/i.test(f.id||'') && f.type==='text')
    if (consultarBtn && criterioTxt) {
      console.log(`  → consultar PATZCUARO (criterio=${criterioTxt.id})`)
      await page.click(`#${criterioTxt.id}`)
      await page.type(`#${criterioTxt.id}`, 'PATZCUARO', { delay: 40 })
      await page.click(`#${consultarBtn.id}`)
      await page.waitForLoadState('domcontentloaded').catch(()=>{})
      await page.waitForFunction(() => !document.body.innerText.includes('Loading…'), { timeout: 60000 }).catch(()=>{})
      await page.waitForTimeout(2500)
      await page.screenshot({ path: join(OUT, `${slug}-result.png`), fullPage: true })
      await writeFile(join(OUT, `${slug}-result.html`), await page.content())

      // Inspeccionar headers de tabla resultante
      const headers = await page.evaluate(() => {
        let best = []
        for (const t of document.querySelectorAll('table')) {
          const h = Array.from(t.querySelectorAll('tr')[0]?.children || []).map(c => c.textContent?.trim()).filter(Boolean)
          if (h.length > best.length) best = h
        }
        return best
      })
      console.log(`  Headers: ${headers.join(' | ')}`)
    } else {
      console.log(`  (sin botón consultar+criterio, no probamos)`)
    }
  } catch (e) {
    console.log(`  ERROR: ${e.message.slice(0,100)}`)
  }
}

await ctx.close()
await browser.close()
console.log(`\n✓ ${OUT}`)
