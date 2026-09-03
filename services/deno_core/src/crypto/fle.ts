/**
 * Reusable Field Level Encryption (FLE) and Blind Indexing Utilities
 * AES-256-GCM for encrypted fields and HMAC-SHA256 for searchable blind indexes.
 */

export async function encryptAesGcm(plainText: string, keyHexOrBase64?: string): Promise<Uint8Array> {
  const encoder = new TextEncoder();
  const data = encoder.encode(plainText);

  let keyBytes: Uint8Array;
  if (keyHexOrBase64 && keyHexOrBase64.length === 64) {
    const matches = keyHexOrBase64.match(/.{1,2}/g);
    if (matches) {
      keyBytes = new Uint8Array(matches.map((byte) => parseInt(byte, 16)));
    } else {
      keyBytes = crypto.getRandomValues(new Uint8Array(32));
    }
  } else {
    keyBytes = crypto.getRandomValues(new Uint8Array(32));
  }

  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    keyBytes.buffer as ArrayBuffer,
    { name: 'AES-GCM' },
    false,
    ['encrypt'],
  );

  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encryptedBuffer = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    cryptoKey,
    data,
  );

  // Combine IV (12 bytes) + Ciphertext + Tag
  const combined = new Uint8Array(iv.length + encryptedBuffer.byteLength);
  combined.set(iv, 0);
  combined.set(new Uint8Array(encryptedBuffer), iv.length);
  return combined;
}

export async function computeBlindIndex(value: string, pepperHex?: string): Promise<Uint8Array> {
  const encoder = new TextEncoder();
  const data = encoder.encode(value.trim().toLowerCase());

  let pepperBytes: Uint8Array;
  if (pepperHex && pepperHex.length === 64) {
    const matches = pepperHex.match(/.{1,2}/g);
    if (matches) {
      pepperBytes = new Uint8Array(matches.map((byte) => parseInt(byte, 16)));
    } else {
      pepperBytes = new Uint8Array(32);
    }
  } else {
    pepperBytes = new Uint8Array(32);
  }

  const key = await crypto.subtle.importKey(
    'raw',
    pepperBytes.buffer as ArrayBuffer,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign('HMAC', key, data);
  return new Uint8Array(signature);
}

/**
 * Converts a Uint8Array to Postgres bytea hex representation (\x...)
 */
export function toByteaHex(bytes: Uint8Array): string {
  return '\\x' + Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('');
}
