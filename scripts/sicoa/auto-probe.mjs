#!/usr/bin/env node
// Auto-probe: ver hasta dónde llegamos sin intervención manual.
// Carga cred de 1Password, navega, screenshot en cada paso.

import { chromium } from 'playwright'
import { mkdir, writeFile } from 'node:fs/promises'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const HERE = dirname(fileURLToPath(import.meta.url))
const OUT = join(HERE, '_capture', 'probe-' + new Date().toISOString().replace(/[:.]/g, '-'))
await mkdir(OUT, { recursive: true })

// Cred: primera del Secure Note
const notes = execSync('op read "op://Personal/SICOA/notesPlain"', { encoding: 'utf8' }).trim()
const [user, pass] = notes.split('|').filter(Boolean)[0].split(':')
console.log(`→ Usando cred: ${user}`)

const browser = await chromium.launch({ headless: true })
const ctx = await browser.newContext({
  recordHar: { path: join(OUT, 'session.har'), content: 'embed' },
  viewport: { width: 1400, height: 900 },
  userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
})
const page = await ctx.newPage()

const log = []
page.on('response', (r) => log.push(`${r.status()} ${r.request().method()} ${r.url()}`))

async function snap(label) {
  await page.screenshot({ path: join(OUT, `${label}.png`), fullPage: true })
  await writeFile(join(OUT, `${label}.html`), await page.content())
  const url = page.url()
  const title = await page.title()
  console.log(`  [${label}] ${title} — ${url}`)
}

try {
  console.log('\n1. GET portal')
  await page.goto('https://sicoa.apeamac.com/', { waitUntil: 'networkidle', timeout: 30000 })
  await page.waitForTimeout(3000)
  await snap('01-landing')

  console.log('\n2. Esperando posible redirect/challenge...')
  await page.waitForTimeout(5000)
  await snap('02-postwait')

  // Buscar campos de login
  const inputs = await page.$$eval('input', (els) =>
    els.map((e) => ({ name: e.name, id: e.id, type: e.type, placeholder: e.placeholder }))
  )
  console.log('\n3. Inputs encontrados:')
  console.log(JSON.stringify(inputs, null, 2))
  await writeFile(join(OUT, 'inputs.json'), JSON.stringify(inputs, null, 2))
} catch (e) {
  console.error('ERROR:', e.message)
  await snap('error')
} finally {
  await writeFile(join(OUT, 'requests.log'), log.join('\n'))
  await ctx.close()
  await browser.close()
  console.log(`\n✓ Capturas en ${OUT}`)
}
