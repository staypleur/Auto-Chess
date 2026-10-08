// Dependency-free Roblox XML place generation. Open the result in Roblox Studio.
const fs = require('node:fs')
const path = require('node:path')
const root = path.resolve(__dirname, '..')
let id = 0
const escape = text => String(text).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;')
function item(kind, name, children='', source) {
  const code = source === undefined ? '' : `<ProtectedString name="Source">${escape(source)}</ProtectedString>`
  return `<Item class="${kind}" referent="RBX${++id}"><Properties><string name="Name">${escape(name)}</string>${code}</Properties>${children}</Item>`
}
const read = file => fs.readFileSync(path.join(root,'src',file),'utf8')
const shared = ['Catalog','Rules'].map(name => item('ModuleScript',name,'',read(`shared/${name}.luau`))).join('')
const services = [
  item('ReplicatedStorage','ReplicatedStorage',item('Folder','AutoChess',shared)),
  item('ServerScriptService','ServerScriptService',item('Script','AutoChessServer','',read('server/Main.server.luau'))),
  item('StarterPlayer','StarterPlayer',item('StarterPlayerScripts','StarterPlayerScripts',
    item('LocalScript','AutoChessClient','',read('client/Main.client.luau')))),
  item('Workspace','Workspace',`<Item class="SpawnLocation" referent="RBXSPAWN"><Properties><string name="Name">Spawn</string><bool name="Anchored">true</bool><Vector3 name="Size"><X>32</X><Y>1</Y><Z>32</Z></Vector3><CoordinateFrame name="CFrame"><X>0</X><Y>0</Y><Z>0</Z><R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22></CoordinateFrame></Properties></Item>`)
].join('')
const xml = `<?xml version="1.0" encoding="utf-8"?><roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="4"><External>null</External><External>nil</External>${services}</roblox>`
const output = path.join(root,'AutoChess.rbxlx')
fs.writeFileSync(output,xml)
console.log(`Built ${output} (${Buffer.byteLength(xml)} bytes)`)
