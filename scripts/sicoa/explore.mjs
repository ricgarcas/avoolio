#!/usr/bin/env node
// Spike SICOA — paso 1: explorar el portal con sesión real.
//
// Arranca Chromium con DevTools, navega a SICOA y deja que tú hagas login
// manual con una clave de 1Password. El script captura:
//   - HAR completo (XHR + form posts) en _capture/session-<ts>.har
//   - HTML de cada página visitada en _capture/pages/
//   - Screenshot al salir
//
// Objetivo: mapear qué endpoints sirven datos (JSON o tablas HTML) para
// luego construir el scraper headless.
//
// Uso:
//   node scripts/sicoa/explore.mjs
//   (cierra la ventana cuando termines — el HAR se guarda solo)

import { chromium } from 'playwright'
import { mkdir, writeFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const HERE = dirname(fileURLToPath(import.meta.url))
const CAPTURE = join(HERE, '_capture')
const PAGES = join(CAPTURE, 'pages')
const PORTAL = 'https://sicoa.apeamac.com'

const ts = new Date().toISOString().replace(/[:.]/g, '-')

await mkdir(PAGES, { recursive: true })

const browser = await chromium.launch({ headless: false, devtools: true })
const ctx = await browser.newContext({
  recordHar: { path: join(CAPTURE, `session-${ts}.har`), content: 'embed' },
  viewport: { width: 1400, height: 900 },
})
const page = await ctx.newPage()

let pageIdx = 0
page.on('framenavigated', async (frame) => {
  if (frame !== page.mainFrame()) return
  const url = frame.url()
  if (!url.startsWith('http')) return
  pageIdx += 1
  try {
    const html = await page.content()
    const slug = url.replace(/[^a-z0-9]+/gi, '_').slice(0, 80)
    await writeFile(join(PAGES, `${String(pageIdx).padStart(3, '0')}-${slug}.html`), html)
    console.log(`[${pageIdx}] ${url}`)
  } catch {}
})

console.log(`\n→ Abriendo ${PORTAL}`)
console.log('→ Inicia sesión con cualquier clave de 1Password (op://Personal/SICOA)')
console.log('→ Navega por reportes / descargas / consultas que te interesen')
console.log('→ Cierra la ventana cuando termines\n')

await page.goto(PORTAL)

await new Promise((resolve) => {
  browser.on('disconnected', resolve)
})

console.log(`\n✓ HAR: _capture/session-${ts}.har`)
console.log(`✓ Pages: _capture/pages/ (${pageIdx} snapshots)`)
