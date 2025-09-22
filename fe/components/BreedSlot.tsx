"use client";

import React, { useEffect, useState } from "react";
import { Avatar } from "@/components/Avatar";
import type { AvatarProps } from "@/components/Avatar";

type WalletNFT = { tokenId: bigint };

export type BreedSlotProps = {
  label: string;
  which: "p1" | "p2";
  token: WalletNFT | null;
  hidden?: boolean;

  /** who escrowed the token (if any); null = not escrowed */
  escrowOwner?: `0x${string}` | null;
  /** true if escrowOwner is the connected user */
  escrowedByYou: boolean;

  /** returns AvatarProps from cache (if available) */
  getAvatarProps: (tokenId: bigint) => AvatarProps | undefined;
  /** ensures details are loaded by tokenId (works even if contract owns it) */
  ensureDetailsByTokenId: (tokenId: bigint) => Promise<void>;

  /** called when user clicks remove (only when not escrowed) */
  onRemove: () => void;
  /** called when user drops an NFT tokenId into this slot */
  onDropTokenId: (tokenId: bigint) => void;
  /** toggles deposit/withdraw (parent handles the actual tx) */
  onToggleDeposit: () => void;
};

export default function BreedSlot({
  label,
  which,
  token,
  hidden,
  escrowOwner,
  escrowedByYou,
  getAvatarProps,
  ensureDetailsByTokenId,
  onRemove,
  onDropTokenId,
  onToggleDeposit,
}: BreedSlotProps) {
  const [dragOver, setDragOver] = useState(false);

  const tid = token?.tokenId;
  const avatar = tid ? getAvatarProps(tid) : undefined;

  const deposited = !!escrowOwner;

  useEffect(() => {
    if (tid && !avatar) {
      // make sure preview exists even if the contract owns the token
      ensureDetailsByTokenId(tid).catch(() => {});
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tid]);

  if (hidden) return null;
  const handleDrop: React.DragEventHandler<HTMLDivElement> = e => {
    e.preventDefault();
    setDragOver(false);
    const raw = e.dataTransfer.getData("text/plain");
    if (!raw) return;
    try {
      onDropTokenId(BigInt(raw));
    } catch {
      // ignore invalid drop
    }
  };

  return (
    <div className="flex flex-col gap-3">
      <div
        onDrop={handleDrop}
        onDragOver={e => {
          e.preventDefault();
          setDragOver(true);
        }}
        onDragLeave={() => setDragOver(false)}
        className={[
          "flex flex-col items-center justify-center rounded-xl h-[380px] w-full transition-colors",
          "border-2 border-dashed",
          dragOver
            ? "border-green-400 bg-green-400/10"
            : "border-black/30 bg-white/5",
        ].join(" ")}
      >
        <div className="text-white/70 mb-2">{label}</div>

        {token && avatar ? (
          <div className="flex flex-col items-center gap-3">
            <div className="w-[220px] h-[220px]">
              <Avatar {...avatar} />
            </div>
            <div className="text-sm text-white/80">
              Token #{String(tid)}
              {deposited && (
                <span
                  className={`mr-14 ${
                    escrowedByYou ? "text-green-300" : "text-yellow-300"
                  }`}
                >
                  {escrowedByYou
                    ? "(escrowed by you)"
                    : "(escrowed by someone else)"}
                </span>
              )}
            </div>
            {!deposited && (
              <button
                className="text-sm text-red-300 hover:text-red-200 underline cursor-pointer"
                onClick={onRemove}
              >
                remove
              </button>
            )}
          </div>
        ) : token && !avatar ? (
          <div className="text-black/60 text-sm">Loading preview…</div>
        ) : (
          <div className="text-black/50">Drop your NFT here</div>
        )}
      </div>

      <div className="flex justify-center">
        <button
          className="btn-primary px-4 py-2"
          disabled={!token || (deposited && !escrowedByYou)} // can't withdraw if not yours
          onClick={onToggleDeposit}
        >
          {!token
            ? `Deposit ${label}`
            : escrowedByYou
            ? `Withdraw ${label}`
            : deposited
            ? "Escrowed (not yours)"
            : `Deposit ${label}`}
        </button>
      </div>
    </div>
  );
}
