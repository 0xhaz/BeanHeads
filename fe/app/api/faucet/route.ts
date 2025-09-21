import { NextRequest, NextResponse } from "next/server";

// Ensure server (Node.js) runtime so `process.env` is available
export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const SUPPORTED = new Set([
  "ETH-SEPOLIA",
  "AVAX-FUJI",
  "MATIC-AMOY",
  "SOL-DEVNET",
  "ARB-SEPOLIA",
  "BASE-SEPOLIA",
]);

export async function POST(req: NextRequest) {
  try {
    // Use a clearer env var name
    const rawKey =
      process.env.CIRCLE_FAUCET_API_KEY || process.env.TEST_API_KEY;
    if (!rawKey) {
      return NextResponse.json(
        { error: "Server misconfigured: CIRCLE_FAUCET_API_KEY missing" },
        { status: 500 }
      );
    }

    // Circle expects "Bearer TEST_API_KEY:xxxxx..."
    const bearer = rawKey.startsWith("TEST_API_KEY:")
      ? rawKey
      : `TEST_API_KEY:${rawKey}`;

    const body = await req.json().catch(() => ({}));
    const address = String(body.address ?? "").trim();
    const blockchain = String(body.blockchain ?? "")
      .trim()
      .toUpperCase();
    const native = Boolean(body.native ?? true);
    const usdc = Boolean(body.usdc ?? true);
    const eurc = Boolean(body.eurc ?? false);

    if (!address || !blockchain) {
      return NextResponse.json(
        { error: "Missing address or blockchain" },
        { status: 400 }
      );
    }
    if (!SUPPORTED.has(blockchain)) {
      return NextResponse.json(
        { error: `Unsupported network '${blockchain}'` },
        { status: 400 }
      );
    }

    const payload = { address, blockchain, native, usdc, eurc };

    const res = await fetch("https://api.circle.com/v1/faucet/drips", {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${bearer}`,
        // Optional but useful to avoid duplicates on retries:
        "Idempotency-Key": crypto.randomUUID(),
      },
      body: JSON.stringify(payload),
      cache: "no-store",
    });

    const text = await res.text();
    let data: any;
    try {
      data = text ? JSON.parse(text) : null;
    } catch {
      data = { raw: text };
    }

    if (!res.ok) {
      // Surface Circle's response for easier debugging
      return NextResponse.json(
        { error: "Circle API error", status: res.status, data },
        { status: res.status }
      );
    }

    return NextResponse.json({ ok: true, data });
  } catch (e: any) {
    return NextResponse.json(
      { error: e?.message ?? "Unexpected error" },
      { status: 500 }
    );
  }
}
