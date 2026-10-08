const fs=require('node:fs')
const path=require('node:path')
const os=require('node:os')
const {spawnSync}=require('node:child_process')
const root=path.resolve(__dirname,'..')
const binary=process.argv[2] || process.env.LUAU_BIN || path.join(__dirname,'luau',process.platform==='win32'?'luau.exe':'luau')
if(!fs.existsSync(binary)) throw new Error('Set LUAU_BIN to the official Luau CLI executable or pass its path.')
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'autochess-tests-'))
fs.mkdirSync(path.join(temp,'src','shared'),{recursive:true})
fs.mkdirSync(path.join(temp,'tests'))
for(const name of fs.readdirSync(path.join(root,'src','shared'))) {
  if(name.endsWith('.luau')) fs.copyFileSync(path.join(root,'src','shared',name),path.join(temp,'src','shared',name))
}
const tests=['lobby.spec.luau','queue.spec.luau','rules.spec.luau','server.spec.luau','queue-server.spec.luau']
for(const name of tests) {
  if(name==='server.spec.luau' || name==='queue-server.spec.luau') {
    const queue=name==='queue-server.spec.luau'
    const fixture=fs.readFileSync(path.join(root,'tests',queue?'queue-server.spec.template':'server.spec.template'),'utf8')
    const server=fs.readFileSync(path.join(root,'src',queue?'lobby':'server',queue?'Queue.server.luau':'Main.server.luau'),'utf8')
    fs.writeFileSync(path.join(temp,'tests',name),fixture.replace('--[[SERVER_SOURCE]]',server))
  } else fs.copyFileSync(path.join(root,'tests',name),path.join(temp,'tests',name))
  const result=spawnSync(binary,[path.join(temp,'tests',name)],{encoding:'utf8'})
  process.stdout.write(result.stdout || '')
  process.stderr.write(result.stderr || '')
  if(result.error) throw result.error
  if(result.status!==0) process.exit(result.status || 1)
}
console.log('Server lifecycle uses mocked Roblox services; Studio engine/visual QA still required.')
