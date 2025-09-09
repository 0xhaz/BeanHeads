import * as fs from "fs";
import path from "path";
import type { Abi } from "viem";

const artifacts = [
  "app/contracts/BeanHeadsDiamond.json",
  "app/contracts/BeanHeadsViewFacet.json",
  "app/contracts/BeanHeadsMintFacet.json",
  "app/contracts/BeanHeadsAdminFacet.json",
  "app/contracts/BeanHeadsBreedingFacet.json",
  "app/contracts/BeanHeadsMarketplaceFacet.json",
  "app/contracts/BeanHeadsMarketplaceSigFacet.json",
];

function normalize(item: any) {
  if (item?.type === "function" && item.outputs === undefined) {
    return { ...item, outputs: [] };
  }
  return item;
}

function sigOf(item: any) {
  if (item.type !== "function") return `${item.type}:${item.name ?? ""}`;
  const ins = (item.inputs ?? []).map((i: any) => i.type).join(",");
  return `function ${item.name}(${ins})`;
}

const merged: any[] = [];
const seen = new Set<string>();

for (const p of artifacts) {
  const json = JSON.parse(fs.readFileSync(path.resolve(p), "utf-8"));
  const abi: any[] = json.abi ?? json;
  for (const _item of abi) {
    const item = normalize(_item);
    const key = sigOf(item);
    if (!seen.has(key)) {
      seen.add(key);
      merged.push(item);
    }
  }
}

const out = {
  abi: merged,
};

fs.writeFileSync(
  "app/contracts/BeanHeadsABI.json",
  JSON.stringify(out, null, 2)
);
console.log(`Merged ${merged.length} unique ABI entries.`);
