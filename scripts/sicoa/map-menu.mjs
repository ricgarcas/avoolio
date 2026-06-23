#!/usr/bin/env node
// Login con una cred válida y mapear todos los items de menú.

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

chromiumExtra.use(StealthPlugin())

const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'menu-' + new Date().toISOString().replace(/[:.]/g, '-'))
await mkdir(OUT, { recursive: true })

const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
const cred = notes.split('|').filter(Boolean)
  .map((c) => { const i = c.indexOf(':'); return { user: c.slice(0,i), pass: c.slice(i+1) } })
  .find((c) => c.user === 'adrian.acmargo')

const browser = await chromiumExtra.launch({ headless: true })
const ctx = await browser.newContext({
  recordHar: { path: join(OUT, 'session.har'), content: 'embed' },
  viewport: { width: 1400, height: 900 },
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
await page.click('#ASPxTxtUsuario'); await page.type('#ASPxTxtUsuario', cred.user, { delay: 50 })
await page.click('#ASPxTxtContra');  await page.type('#ASPxTxtContra', cred.pass, { delay: 50 })
await Promise.all([
  page.waitForLoadState('networkidle', { timeout: 20000 }).catch(() => {}),
  page.click('#ASPxBtnIniciarSesion'),
])
await page.waitForTimeout(3000)
await page.screenshot({ path: join(OUT, 'dashboard.png'), fullPage: true })

// Esperar a hover sobre cada menú top-level y capturar submenús.
const tops = ['Inicio', 'Listados', 'Estadisticas', 'Estadísticas', 'Operaciones']
const menuMap = {}

for (const label of tops) {
  try {
    const handle = await page.$(`a:has-text("${label}"), span:has-text("${label}")`)
    if (!handle) continue
    await handle.hover()
    await page.waitForTimeout(800)
    await page.screenshot({ path: join(OUT, `menu-${label}.png`), fullPage: true })

    // Capturar HTML para extraer submenús visibles
    const html = await page.content()
    // Buscar todos los links que aparecen tras el hover
    const items = await page.$$eval('a, td[onclick], div[onclick]', (els) =>
      els
        .filter((e) => {
          const r = e.getBoundingClientRect()
          return r.width > 0 && r.height > 0
        })
        .map((e) => ({
          text: e.textContent?.trim().slice(0, 80),
          href: e.getAttribute?.('href') || null,
          onclick: e.getAttribute?.('onclick') || null,
          id: e.id || null,
        }))
        .filter((x) => x.text && x.text.length > 0)
    )
    menuMap[label] = items
    console.log(`  ${label}: ${items.length} items visibles`)
  } catch (e) {
    console.log(`  ${label}: ERROR ${e.message.slice(0, 60)}`)
  }
}

// También capturar todo el HTML del body por si los menús están en línea
const bodyHtml = await page.content()
await writeFile(join(OUT, 'dashboard.html'), bodyHtml)
await writeFile(join(OUT, 'menus.json'), JSON.stringify(menuMap, null, 2))
await writeFile(join(OUT, 'requests.log'), reqLog.join('\n'))

// Frames? a veces estos sistemas usan frames clásicos
const frames = page.frames().map((f) => ({ name: f.name(), url: f.url() }))
await writeFile(join(OUT, 'frames.json'), JSON.stringify(frames, null, 2))
console.log(`\n  Frames: ${frames.length}`)
frames.forEach((f) => console.log(`    ${f.name || '(main)'} → ${f.url}`))

await ctx.close()
await browser.close()
console.log(`\n✓ ${OUT}`)
