#!/usr/bin/env node
// Probe BICO cuidadoso: login + 1 query + screenshot. Esperas largas.

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

chromiumExtra.use(StealthPlugin())
const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'bico-careful-' + new Date().toISOString().replace(/[:.]/g, '-'))
await mkdir(OUT, { recursive: true })

const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
const cred = notes.split('|').filter(Boolean)
  .map((c) => { const i = c.indexOf(':'); return { user: c.slice(0,i), pass: c.slice(i+1) } })
  .find((c) => c.user === 'RO.LEMO')

console.log(`→ Cred: ${cred.user}`)
console.log(`→ IP pública (vía VPN, espero):`)
console.log(execSync('curl -s --max-time 10 https://ifconfig.me || echo "?"', { encoding: 'utf8' }))

const browser = await chromiumExtra.launch({ headless: true })
const ctx = await browser.newContext({
  recordHar: { path: join(OUT, 'session.har'), content: 'embed' },
  viewport: { width: 1600, height: 1200 },
  locale: 'es-MX',
  userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
})
const page = await ctx.newPage()

console.log('\n[1/4] Cargando portal...')
await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'domcontentloaded', timeout: 60000 })
await page.waitForTimeout(8000)  // esperar Radware
await page.screenshot({ path: join(OUT, '01-portal.png') })

const html1 = await page.content()
if (html1.includes('ANOMALY DETECTED') || html1.includes('We are sorry')) {
  console.error('  ✗ Radware sigue bloqueando esta IP. Abortando.')
  await browser.close()
  process.exit(1)
}
if (!html1.includes('ASPxTxtUsuario')) {
  console.error('  ✗ No es la página de login. Pude haber sido redirigido.')
  await browser.close()
  process.exit(1)
}
console.log('  ✓ Login form visible')

console.log('\n[2/4] Login...')
await page.click('#ASPxTxtUsuario')
await page.type('#ASPxTxtUsuario', cred.user, { delay: 80 })
await page.waitForTimeout(800)
await page.click('#ASPxTxtContra')
await page.type('#ASPxTxtContra', cred.pass, { delay: 80 })
await page.waitForTimeout(800)
await page.click('#ASPxBtnIniciarSesion')
await page.waitForLoadState('domcontentloaded').catch(() => {})
await page.waitForTimeout(5000)
await page.screenshot({ path: join(OUT, '02-postlogin.png') })

const html2 = await page.content()
if (html2.includes('Contraseña incorrecta')) { console.error('  ✗ Contraseña incorrecta'); process.exit(1) }
if (html2.includes('ANOMALY DETECTED')) { console.error('  ✗ Radware ban post-login'); process.exit(1) }
console.log('  ✓ Login OK')

console.log('\n[3/4] Cargando BICO (con espera larga)...')
await page.waitForTimeout(4000)
await page.goto('https://sicoa.senasica.gob.mx/DetallesGeograficosDeEmisionDelBICO.aspx', {
  waitUntil: 'domcontentloaded',
  timeout: 60000,
})
await page.waitForTimeout(6000)
await page.addStyleTag({ content: '#wmContenedor{display:none !important;}' }).catch(()=>{})
await page.screenshot({ path: join(OUT, '03-bico-form.png'), fullPage: true })
await writeFile(join(OUT, '03-bico-form.html'), await page.content())

const html3 = await page.content()
if (html3.includes('ANOMALY DETECTED')) {
  console.error('  ✗ Radware tira BICO específicamente. Abortando.')
  await browser.close()
  process.exit(1)
}

// Inspeccionar formulario
const fields = await page.$$eval('input, select, textarea', (els) =>
  els.filter(e => e.id || e.name).map(e => ({
    tag: e.tagName, type: e.type, id: e.id, name: e.name,
    placeholder: e.placeholder?.slice(0,40),
  }))
)
const interesting = fields.filter(f => !/^ctl00/i.test(f.id) || /criterio|busqueda|estado|consultar|huerta|clave|productor|sagarpa|btn|tb/i.test(f.id))
console.log(`  Fields: ${interesting.length}`)
interesting.forEach(f => console.log(`    ${f.tag}/${f.type} id=${f.id}`))

await ctx.close()
await browser.close()
console.log(`\n✓ ${OUT}`)
