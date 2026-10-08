import fs from 'node:fs'
import { precomputedPokemons } from '../../app/models/precomputed/precomputed-pokemons'
import { PkmFamily } from '../../app/types/enum/Pokemon'
import { RarityCost, RarityProbabilityPerLevel } from '../../app/config/game/shop'
import { SynergyTiersThresholds } from '../../app/config/game/synergies'

function lua(value: any): string {
  if (value === undefined || value === null) return 'nil'
  if (typeof value === 'string') return JSON.stringify(value)
  if (typeof value === 'number' || typeof value === 'boolean') return String(value)
  if (Array.isArray(value)) return `{${value.map(lua).join(',')}}`
  return `{${Object.entries(value).map(([k,v]) => `[${lua(k)}]=${lua(v)}`).join(',')}}`
}
const units: Record<string, any> = {}
for (const p of precomputedPokemons) {
  units[p.name] = { name: p.name, family: PkmFamily[p.name], index: p.index,
    hp: p.hp, attack: p.atk, defense: p.def, speed: p.speed, range: p.range,
    stars: p.stars, rarity: p.rarity, cost: RarityCost[p.rarity],
    types: Array.from(p.types.values()), skill: p.skill, passive: p.passive,
    evolution: p.evolution, evolutionRule: p.evolutionRule?.type,
    copies: (p.evolutionRule as any)?.numberRequired,
    additional: p.additional, regional: p.regional }
}
fs.writeFileSync('roblox/src/shared/Catalog.luau',
  '-- Generated from the pinned upstream production snapshot; do not edit by hand.\nreturn '+
  lua({units, odds: RarityProbabilityPerLevel, thresholds: SynergyTiersThresholds})+'\n')
console.log(`Exported ${Object.keys(units).length} Pokemon definitions`)
