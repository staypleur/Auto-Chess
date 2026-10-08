const fs = require('node:fs')
const net = require('node:net')
const path = require('node:path')
require('dotenv').config({ quiet: true })

const required = ['MONGO_URI', 'FIREBASE_API_KEY', 'FIREBASE_AUTH_DOMAIN',
  'FIREBASE_PROJECT_ID', 'FIREBASE_STORAGE_BUCKET', 'FIREBASE_MESSAGING_SENDER_ID',
  'FIREBASE_APP_ID', 'FIREBASE_CLIENT_EMAIL', 'FIREBASE_PRIVATE_KEY']
let errors = 0
function check(ok, message) {
  console.log(`${ok ? '[OK]' : '[MISSING]'} ${message}`)
  if (!ok) errors++
}
async function main() {
  check(Number(process.versions.node.split('.')[0]) >= 24, 'Node.js 24 or newer')
  check(fs.existsSync('.env'), '.env exists (copy .env.local.example)')
  for (const key of required) check(Boolean(process.env[key]?.trim()), `${key} configured`)
  if (process.env.FIREBASE_PRIVATE_KEY) {
    const { createPrivateKey } = require('node:crypto')
    let valid = false
    try {
      createPrivateKey(process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'))
      valid = true
    } catch {}
    check(valid, 'Firebase private key is a valid PEM key')
  }
  for (const directory of ['app/public/dist/client/assets', 'app/public/dist/client/locales']) {
    check(fs.existsSync(directory) && fs.readdirSync(directory).length > 0,
      `${directory} prepared (npm run assetpack)`)
  }
  check(fs.existsSync(path.join('node_modules', 'tsx')), 'Server dependencies installed')
  const uri = process.env.MONGO_URI
  if (uri) {
    try {
      const url = new URL(uri)
      check(['mongodb:', 'mongodb+srv:'].includes(url.protocol), 'MongoDB URI scheme')
      if (['localhost', '127.0.0.1'].includes(url.hostname)) {
        const reachable = await new Promise(resolve => {
          const socket = net.createConnection({ host: url.hostname, port: Number(url.port || 27017) })
          const finish = value => { socket.destroy(); resolve(value) }
          socket.setTimeout(2000)
          socket.once('connect', () => finish(true))
          socket.once('error', () => finish(false))
          socket.once('timeout', () => finish(false))
        })
        check(reachable, 'Local MongoDB port reachable (database authentication not tested)')
      }
    } catch { check(false, 'MongoDB URI format') }
  }
  console.log(errors ? `\n${errors} prerequisite(s) missing. See docs/LOCAL-KO.md.` :
    '\nLocal prerequisites ready. Firebase authentication still needs a browser login test.')
  process.exitCode = errors ? 1 : 0
}
main().catch(() => { console.error('Local prerequisite check failed.'); process.exitCode = 1 })
