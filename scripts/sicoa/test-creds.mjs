#!/usr/bin/env node
// Prueba cada cred y reporta cuáles loguean. Reutiliza un solo browser.

import { chromium as chromiumExtra } from 'playwright-extra'
import StealthPlugin from 'puppeteer-extra-plugin-stealth'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

chromiumExtra.use(StealthPlugin())

const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'cred-test-' + new Date().toISOString().replace(/[:.]/g, '-'))
await mkdir(OUT, { recursive: true })

const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
const creds = notes.split('|').filter(Boolean).map((c) => {
  const idx = c.indexOf(':')
  return { user: c.slice(0, idx), pass: c.slice(idx + 1) }
})

const browser = await chromiumExtra.launch({ headless: true })
const results = []

for (const { user, pass } of creds) {
  const ctx = await browser.newContext({
    viewport: { width: 1400, height: 900 },
    locale: 'es-MX',
    userAgent:
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  })
  const page = await ctx.newPage()
  let status = 'unknown'
  let urlFinal = ''
  let titleFinal = ''

  try {
    await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'domcontentloaded', timeout: 30000 })
    await page.waitForSelector('#ASPxTxtUsuario', { timeout: 15000 })
    await page.waitForTimeout(1500)
    await page.click('#ASPxTxtUsuario')
    await page.type('#ASPxTxtUsuario', user, { delay: 40 })
    await page.click('#ASPxTxtContra')
    await page.type('#ASPxTxtContra', pass, { delay: 40 })
    await Promise.all([
      page.waitForLoadState('networkidle', { timeout: 20000 }).catch(() => {}),
      page.click('#ASPxBtnIniciarSesion'),
    ])
    await page.waitForTimeout(3000)

    urlFinal = page.url()
    titleFinal = await page.title()
    const html = await page.content()
    const hasLogin = html.includes('ASPxTxtContra') || html.includes('Iniciar sesión')
    const hasError =
      html.includes('Contraseña incorrecta') ||
      html.includes('incorrecta') ||
      html.includes('inválido') ||
      html.includes('Usuario no')
    status = hasError ? 'BAD_CRED' : !hasLogin ? 'OK' : 'AMBIGUOUS'

    const slug = user.replace(/[^a-z0-9]+/gi, '_')
    await page.screenshot({ path: join(OUT, `${slug}.png`), fullPage: true })
    if (status === 'OK') await writeFile(join(OUT, `${slug}.html`), html)
  } catch (e) {
    status = 'ERROR:' + e.message.slice(0, 60)
  } finally {
    await ctx.close()
  }

  results.push({ user, status, url: urlFinal, title: titleFinal })
  console.log(`  ${status.padEnd(15)} ${user}`)
}

await browser.close()
await writeFile(join(OUT, 'results.json'), JSON.stringify(results, null, 2))
console.log(`\n${results.filter((r) => r.status === 'OK').length} de ${results.length} válidas`)
console.log(`✓ ${OUT}`)
