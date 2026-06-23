#!/usr/bin/env node
// Auto-login con stealth + eventos de teclado reales.
// Radware Bot Manager (stormcaster.js) inspecciona Playwright; usamos
// puppeteer-extra-plugin-stealth + page.type() con delay para parecer humano.

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

chromiumExtra.use(StealthPlugin())

const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'stealth-' + new Date().toISOString().replace(/[:.]/g, '-'))
await mkdir(OUT, { recursive: true })

const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
const creds = notes.split('|').filter(Boolean).map((c) => {
  const [u, p] = c.split(':')
  return { user: u, pass: p }
})
const [{ user, pass }] = creds
console.log(`→ Login como: ${user}`)

const browser = await chromiumExtra.launch({ headless: true })
const ctx = await browser.newContext({
  recordHar: { path: join(OUT, 'session.har'), content: 'embed' },
  viewport: { width: 1400, height: 900 },
  locale: 'es-MX',
  timezoneId: 'America/Mexico_City',
  userAgent:
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
})
const page = await ctx.newPage()

const reqLog = []
page.on('response', (r) => reqLog.push(`${r.status()} ${r.request().method()} ${r.url()}`))

async function snap(label) {
  await page.screenshot({ path: join(OUT, `${label}.png`), fullPage: true })
  await writeFile(join(OUT, `${label}.html`), await page.content())
  console.log(`  [${label}] ${page.url()}`)
}

try {
  console.log('\n1. Portal…')
  await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'domcontentloaded', timeout: 30000 })
  await page.waitForSelector('#ASPxTxtUsuario', { timeout: 15000 })
  await page.waitForTimeout(2000) // dejar que stormcaster termine
  await snap('01-login')

  console.log('\n2. Llenando con typing real…')
  await page.click('#ASPxTxtUsuario')
  await page.type('#ASPxTxtUsuario', user, { delay: 80 })
  await page.click('#ASPxTxtContra')
  await page.type('#ASPxTxtContra', pass, { delay: 80 })
  await page.waitForTimeout(500)
  await snap('02-filled')

  console.log('\n3. Click submit…')
  await Promise.all([
    page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {}),
    page.click('#ASPxBtnIniciarSesion'),
  ])
  await page.waitForTimeout(4000)
  await snap('03-postlogin')

  console.log(`\n   URL final: ${page.url()}`)
  console.log(`   Title: ${await page.title()}`)

  console.log('\n4. Mapeando menú…')
  const links = await page.$$eval('a[href]', (els) =>
    els
      .map((e) => ({ href: e.getAttribute('href'), text: e.textContent?.trim().slice(0, 80) }))
      .filter((l) => l.href && !l.href.startsWith('#') && !l.href.startsWith('javascript:'))
  )
  const unique = [...new Map(links.map((l) => [l.href, l])).values()]
  await writeFile(join(OUT, 'links.json'), JSON.stringify(unique, null, 2))
  console.log(`   ${unique.length} links únicos`)
} catch (e) {
  console.error('\nERROR:', e.message)
  await snap('error')
} finally {
  await writeFile(join(OUT, 'requests.log'), reqLog.join('\n'))
  await ctx.close()
  await browser.close()
  console.log(`\n✓ ${OUT}`)
}
