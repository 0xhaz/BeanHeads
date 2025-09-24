"use client";

import React, { useEffect, useState } from "react";
import { useActiveAccount, useActiveWalletChain } from "thirdweb/react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useBeanHeads } from "@/context/beanheads";
import { useBreeder } from "@/context/breeder";
import { Avatar } from "@/components/Avatar";
import type { AvatarProps } from "@/components/Avatar";
import BreedSlot from "@/components/BreedSlot";
import { BreedingMode } from "@/types/Breeding";
import { USDC_ADDRESS } from "@/constants/contract";
import { type SVGParams, svgParamsToAvatarProps } from "@/utils/avatarMapping";
import { normalizeSvgParams } from "@/utils/normalizeSvgParams";
import Link from "next/link";
import CollectionCard from "@/components/CollectionCard";
import { toast } from "sonner";

type WalletNFT = { tokenId: bigint };

const MAX_BREEDS = 5;

const BreedingPage = () => {
  const account = useActiveAccount();
  const chain = useActiveWalletChain();

  const {
    getOwnerTokens,
    getAttributesByOwner,
    getAttributesByTokenId,
    getGeneration,
    getOwnerOf,
  } = useBeanHeads();

  const {
    getContractAddress,
    requestBreed,
    depositBeanHeads,
    withdrawBeanHeads,
    getEscrowedTokenOwner,
    getRarityPoints,
    getParentBreedingCount,
  } = useBreeder();

  const [loadingList, setLoadingList] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [tokens, setTokens] = useState<WalletNFT[]>([]);
  const [detailsCache, setDetailsCache] = useState<
    Record<string, { params?: SVGParams; generation?: bigint }>
  >({});
  const [loadingMap, setLoadingMap] = useState<Record<string, boolean>>({});
  const [isOpen, setIsOpen] = useState<string | null>(null);

  const [parent1, setParent1] = useState<WalletNFT | null>(null);
  const [parent2, setParent2] = useState<WalletNFT | null>(null);
  const [mode, setMode] = useState<number>(BreedingMode.NewBreed);
  const [rarityPoints, setRarityPoints] = useState<Record<string, bigint>>({});
  const [breedCounts, setBreedCounts] = useState<Record<string, bigint>>({});

  // tokenId -> escrow owner (or null if not escrowed)
  const [escrowedOwner, setEscrowedOwner] = useState<
    Record<string, `0x${string}` | null>
  >({});

  /* ---------- persistence helpers ---------- */
  const lsKey = (addr?: string | null, chainId?: number) =>
    addr && chainId ? `bh:slots:${chainId}:${addr.toLowerCase()}` : null;

  function saveSlots(
    addr: string | undefined,
    chainId: number | undefined,
    p1: bigint | null,
    p2: bigint | null
  ) {
    const key = lsKey(addr, chainId);
    if (!key) return;
    localStorage.setItem(
      key,
      JSON.stringify({
        p1: p1 ? p1.toString() : null,
        p2: p2 ? p2.toString() : null,
      })
    );
  }
  function loadSlots(addr: string | undefined, chainId: number | undefined) {
    const key = lsKey(addr, chainId);
    if (!key) return { p1: null as bigint | null, p2: null as bigint | null };
    try {
      const raw = localStorage.getItem(key);
      if (!raw) return { p1: null, p2: null };
      const obj = JSON.parse(raw);
      return {
        p1: obj?.p1 ? BigInt(obj.p1) : null,
        p2: obj?.p2 ? BigInt(obj.p2) : null,
      };
    } catch {
      return { p1: null, p2: null };
    }
  }

  async function fetchRarityPoints(tokenId: bigint) {
    const key = tokenId.toString();
    try {
      const points = await getRarityPoints(tokenId);
      setRarityPoints(prev => ({ ...prev, [key]: points }));
    } catch (e) {
      console.error(`fetchRarityPoints #${key}:`, e);
    }
  }

  const fetchBreedCount = async (tokenId: bigint) => {
    const key = tokenId.toString();
    try {
      if (getParentBreedingCount) {
        const count = await getParentBreedingCount(tokenId);
        setBreedCounts(prev => ({ ...prev, [key]: count }));
      } else {
        console.warn("getParentBreedingCount is undefined");
      }
    } catch (e) {
      console.error(`Error fetching breed count for token ${tokenId}:`, e);
    }
  };

  async function tokenExists(tokenId: bigint) {
    try {
      await getOwnerOf(tokenId);
      return true;
    } catch {
      return false;
    }
  }

  async function assertBreedable(tid: bigint): Promise<boolean> {
    const key = tid.toString();
    let count = breedCounts[key];

    try {
      if (count === undefined) {
        if (!getParentBreedingCount) return true;
        count = await getParentBreedingCount(tid);
        setBreedCounts(prev => ({ ...prev, [key]: count! }));
      }
    } catch (e) {
      console.error(`assertBreedable #${key}:`, e);
      return true;
    }

    if ((count as bigint) >= BigInt(MAX_BREEDS)) {
      toast(
        `BeanHead #${key} has reached the maximum number of breeds (${MAX_BREEDS}).`
      );
      return false;
    }
    return true;
  }

  /* ---------- data loaders ---------- */
  async function refreshEscrowedStatus(tid: bigint) {
    // safe probe: try mapping, fall back to ownerOf
    try {
      const who = await getEscrowedTokenOwner(tid);
      if (who) {
        setEscrowedOwner(m => ({ ...m, [tid.toString()]: who }));
        return;
      }
    } catch {
      // ignore
    }
    try {
      const onChainOwner = await getOwnerOf(tid);
      // if contract owns it, we know it's escrowed but we don’t know depositor
      // store null to mark "escrowed (unknown)" OR leave as null to mark not-escrowed
      // here we’ll keep null and rely on mapping for depositor; tweak if needed.
      // setEscrowedOwner(m => ({ ...m, [tid.toString()]: null }));
      setEscrowedOwner(m => ({ ...m, [tid.toString()]: null }));
    } catch {
      setEscrowedOwner(m => ({ ...m, [tid.toString()]: null }));
    }
  }

  const loadTokenDetailsByOwner = async (tokenId: bigint) => {
    const key = tokenId.toString();
    if (loadingMap[key]) return;
    try {
      setLoadingMap(m => ({ ...m, [key]: true }));
      const owner = account!.address as `0x${string}`;
      const [raw, generation] = await Promise.all([
        getAttributesByOwner(owner, tokenId),
        getGeneration(tokenId),
      ]);
      setDetailsCache(prev => ({
        ...prev,
        [key]: {
          ...(prev[key] ?? {}),
          params: raw ? normalizeSvgParams(raw) : prev[key]?.params,
          generation,
        },
      }));
      if (!rarityPoints[key]) await fetchRarityPoints(tokenId);
      if (!breedCounts[key]) await fetchBreedCount(tokenId);
    } finally {
      setLoadingMap(m => ({ ...m, [key]: false }));
    }
  };

  const loadTokenDetailsByTokenId = async (tokenId: bigint) => {
    const key = tokenId.toString();
    if (loadingMap[key]) return;
    try {
      setLoadingMap(m => ({ ...m, [key]: true }));

      if (!(await tokenExists(tokenId))) {
        setDetailsCache(prev => {
          const { [key]: _, ...rest } = prev;
          return rest;
        });
        return;
      }
      const raw = await getAttributesByTokenId(tokenId);
      const generation = await getGeneration(tokenId);
      setDetailsCache(prev => ({
        ...prev,
        [key]: {
          ...(prev[key] ?? {}),
          params: raw ? normalizeSvgParams(raw) : prev[key]?.params,
          generation,
        },
      }));
      if (!rarityPoints[key]) await fetchRarityPoints(tokenId);
      if (!breedCounts[key]) await fetchBreedCount(tokenId);
    } finally {
      setLoadingMap(m => ({ ...m, [key]: false }));
    }
  };

  /* ---------- effects ---------- */
  useEffect(() => {
    if (!account?.address) return;
    (async () => {
      setLoadingList(true);
      setError(null);
      try {
        const owner = account.address as `0x${string}`;
        const ids = await getOwnerTokens(owner);
        setTokens(ids.map(id => ({ tokenId: id })));
      } catch (e) {
        console.error(e);
        setError("Failed to load tokens");
      } finally {
        setLoadingList(false);
      }
    })();
  }, [account?.address, getOwnerTokens]);

  useEffect(() => {
    if (!account?.address || !chain?.id) return;
    const { p1, p2 } = loadSlots(account.address, chain.id);
    if (p1) {
      setParent1({ tokenId: p1 });
      fetchRarityPoints(p1);
    }
    if (p2) {
      setParent2({ tokenId: p2 });
      fetchRarityPoints(p2);
    }

    (async () => {
      const list = [p1, p2].filter(Boolean) as bigint[];
      await Promise.all(
        list.map(async tid => {
          await refreshEscrowedStatus(tid);
          await loadTokenDetailsByTokenId(tid);
        })
      );
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [account?.address, chain?.id]);

  useEffect(() => {
    if (mode === BreedingMode.Ascension) {
      setParent2(null);
      // also clear LS
      saveSlots(account?.address, chain?.id, parent1?.tokenId ?? null, null);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mode]);

  useEffect(() => {
    if (!account?.address || !chain?.id) return;
    const { p1, p2 } = loadSlots(account.address, chain.id);

    (async () => {
      let nextP1 = p1 ?? null;
      let nextP2 = p2 ?? null;

      if (nextP1 && !(await tokenExists(nextP1))) {
        nextP1 = null;
      }
      if (nextP2 && !(await tokenExists(nextP2))) {
        nextP2 = null;
      }

      if (nextP1 && !(await assertBreedable(nextP1))) {
        nextP1 = null;
      }
      if (nextP2 && !(await assertBreedable(nextP2))) {
        nextP2 = null;
      }

      setParent1(nextP1 ? { tokenId: nextP1 } : null);
      setParent2(nextP2 ? { tokenId: nextP2 } : null);
      saveSlots(account.address, chain.id, nextP1, nextP2);

      const live = [nextP1, nextP2].filter(Boolean) as bigint[];
      await Promise.all(
        live.map(async tid => {
          await refreshEscrowedStatus(tid);
          await loadTokenDetailsByTokenId(tid);
        })
      );
    })();
  }, [account?.address, chain?.id]);

  /* ---------- actions ---------- */
  async function handleDepositToggle(which: "p1" | "p2") {
    const item = which === "p1" ? parent1 : parent2;
    if (!item || !account || !chain) return;

    try {
      const currentOwner = await getOwnerOf(item.tokenId);
      const breederAddress = await getContractAddress(chain.id);

      const isEscrowed =
        currentOwner.toLowerCase() === breederAddress.toLowerCase();
      const isMine =
        account.address &&
        (
          await getEscrowedTokenOwner(item.tokenId).catch(() => null)
        )?.toLowerCase() === account.address.toLowerCase();

      if (isEscrowed) {
        if (!isMine) {
          return toast("This token is escrowed by another user");
        }

        await withdrawBeanHeads(item.tokenId);

        if (which === "p1") setParent1(null);
        else setParent2(null);

        saveSlots(
          account.address,
          chain?.id,
          which === "p1" ? null : parent1?.tokenId ?? null,
          which === "p2" ? null : parent2?.tokenId ?? null
        );

        toast(`Withdrew token #${String(item.tokenId)}`);
      } else {
        if (!(await assertBreedable(item.tokenId))) {
          if (which === "p1") setParent1(null);
          else setParent2(null);

          saveSlots(
            account.address,
            chain?.id,
            which === "p1" ? item.tokenId : parent1?.tokenId ?? null,
            which === "p2" ? item.tokenId : parent2?.tokenId ?? null
          );
          return;
        }

        await depositBeanHeads(item.tokenId);
        await loadTokenDetailsByTokenId(item.tokenId);

        toast(`Deposited token #${String(item.tokenId)}`);
      }

      await refreshEscrowedStatus(item.tokenId);
    } catch (e) {
      console.error(e);
      toast("Action failed");
    }
  }

  async function handleBreed() {
    if (!account || !chain)
      return toast("Connect your wallet and select a network");

    if (mode === BreedingMode.Ascension) {
      if (!parent1) return toast("Select Token 1 (Ascension uses only one)");
    } else {
      if (!parent1 || !parent2) return toast("Select both tokens");
      if (parent1.tokenId === parent2.tokenId)
        return toast("Cannot breed the same token");
    }

    const tokenAddr = USDC_ADDRESS[chain.id as keyof typeof USDC_ADDRESS];
    if (!tokenAddr) {
      toast("USDC not configured for this network");
      return;
    }

    try {
      const p1 = parent1!.tokenId;
      const p2 = mode === BreedingMode.Ascension ? BigInt(0) : parent2!.tokenId;
      await requestBreed(p1, p2, mode as any, tokenAddr);

      if (mode == BreedingMode.Mutation) {
        setParent1(null);
        saveSlots(account.address, chain?.id, null, parent2?.tokenId ?? null);
      } else if (mode == BreedingMode.Fusion) {
        setParent1(null);
        setParent2(null);
        saveSlots(account.address, chain?.id, null, null);
      }
      toast("Breed request submitted");
    } catch (e) {
      console.error(e);
      toast("Breeding failed");
    }
  }

  /* ---------- helpers ---------- */
  const inSlots = (tid: bigint) =>
    parent1?.tokenId === tid || parent2?.tokenId === tid;

  const getAvatarProps = (tokenId: bigint): AvatarProps | undefined => {
    const cached = detailsCache[tokenId.toString()];
    return cached?.params ? svgParamsToAvatarProps(cached.params) : undefined;
  };

  /* ---------- render gates ---------- */
  if (!account?.address) {
    return (
      <div className="p-8 text-center text-lg">
        Please connect your wallet to view your collections.
      </div>
    );
  }
  if (loadingList)
    return <div className="p-8 text-center text-lg">Loading your tokens…</div>;
  if (error) return <div className="p-8 text-center text-red-400">{error}</div>;
  if (tokens.length === 0) {
    return (
      <div className="p-8 text-center text-lg">
        You do not own any BeanHeads NFTs yet.{" "}
        <Link href="/tasks/minter" className="text-blue-500 underline">
          Mint one now!
        </Link>
      </div>
    );
  }

  const escOwner1 = parent1
    ? escrowedOwner[parent1.tokenId.toString()] ?? null
    : null;
  const escOwner2 = parent2
    ? escrowedOwner[parent2.tokenId.toString()] ?? null
    : null;
  const escByYou = (owner: `0x${string}` | null) =>
    !!(
      owner &&
      account?.address &&
      owner.toLowerCase() === account.address.toLowerCase()
    );

  /* ---------- UI ---------- */
  return (
    <div className="p-6 ">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold underline">Breeder</h1>
        <div className="flex items-center gap-3">
          <Select value={String(mode)} onValueChange={v => setMode(Number(v))}>
            <SelectTrigger className="bg-white/10 border border-white/20 rounded px-3 py-2 text-black w-[200px]">
              <SelectValue placeholder="Select breeding mode" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={String(BreedingMode.NewBreed)}>
                New Breed
              </SelectItem>
              <SelectItem value={String(BreedingMode.Mutation)}>
                Mutation
              </SelectItem>
              <SelectItem value={String(BreedingMode.Fusion)}>
                Fusion
              </SelectItem>
              <SelectItem value={String(BreedingMode.Ascension)}>
                Ascension
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      <div
        className={`grid ${
          mode === BreedingMode.Ascension
            ? "grid-cols-1"
            : "grid-cols-1 md:grid-cols-2"
        } gap-8`}
      >
        <BreedSlot
          label="Token 1"
          which="p1"
          token={parent1}
          escrowOwner={escOwner1 as any}
          escrowedByYou={escByYou(escOwner1)}
          getAvatarProps={getAvatarProps}
          ensureDetailsByTokenId={loadTokenDetailsByTokenId}
          onRemove={() => {
            setParent1(null);
            saveSlots(
              account?.address,
              chain?.id,
              null,
              parent2?.tokenId ?? null
            );
          }}
          onDropTokenId={async tid => {
            if (!(await assertBreedable(tid))) return;
            setParent1({ tokenId: tid });
            refreshEscrowedStatus(tid);
            loadTokenDetailsByTokenId(tid);
          }}
          onToggleDeposit={() => handleDepositToggle("p1")}
        />

        <BreedSlot
          label="Token 2"
          which="p2"
          token={parent2}
          hidden={mode === BreedingMode.Ascension}
          escrowOwner={escOwner2 as any}
          escrowedByYou={escByYou(escOwner2)}
          getAvatarProps={getAvatarProps}
          ensureDetailsByTokenId={loadTokenDetailsByTokenId}
          onRemove={() => {
            setParent2(null);
            saveSlots(
              account?.address,
              chain?.id,
              parent1?.tokenId ?? null,
              null
            );
          }}
          onDropTokenId={async tid => {
            if (!(await assertBreedable(tid))) return;
            setParent2({ tokenId: tid });
            refreshEscrowedStatus(tid);
            loadTokenDetailsByTokenId(tid);
          }}
          onToggleDeposit={() => handleDepositToggle("p2")}
        />
      </div>

      <div className="mt-6 flex justify-center">
        <button className="btn-primary px-6 py-3 text-lg" onClick={handleBreed}>
          Breed
        </button>
      </div>

      {/* Wallet NFTs */}
      <div className="mt-10">
        <div className="text-lg mb-2">Your NFTs</div>
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8 p-4">
          {tokens.map(({ tokenId }) => {
            const key = tokenId.toString();
            const cached = detailsCache[key];
            const inFlight = !!loadingMap[key];
            const props = cached?.params
              ? svgParamsToAvatarProps(cached.params)
              : undefined;
            const disabled = inSlots(tokenId);

            return (
              <div
                key={key}
                draggable={!disabled}
                onDragStart={e => {
                  e.dataTransfer.setData("text/plain", String(tokenId));
                  e.dataTransfer.effectAllowed = "copy";
                }}
                className={[
                  "group relative h-[250px] w-[250px] rounded-3xl border-4 border-white shadow-lg overflow-hidden",
                  disabled ? "opacity-50 cursor-not-allowed" : "cursor-grab",
                ].join(" ")}
              >
                {props ? (
                  <Avatar {...props} />
                ) : (
                  <div className="w-full h-full bg-white/5 flex items-center justify-center text-white/70">
                    BeanHead #{key}
                  </div>
                )}

                {!disabled && (
                  <div
                    className="absolute inset-0 flex items-center justify-center bg-black/70 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-3xl cursor-pointer"
                    onClick={() => {
                      setIsOpen(key);
                      if (!cached && !inFlight)
                        loadTokenDetailsByOwner(tokenId);
                    }}
                  >
                    <div className="text-white text-lg font-bold">
                      {cached
                        ? "View Details"
                        : inFlight
                        ? "Loading…"
                        : "Load Details"}
                    </div>
                  </div>
                )}

                {isOpen === key && cached && !disabled && (
                  <div className="fixed inset-0 z-50">
                    <CollectionCard
                      tokenId={tokenId}
                      params={cached.params!}
                      generation={cached.generation!}
                      rarityPoints={rarityPoints[key]}
                      breedCount={breedCounts[key]}
                      loading={false}
                      onClose={() => setIsOpen(null)}
                    />
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default BreedingPage;
