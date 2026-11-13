/**
 * tokens.ts — token storage (D55, expert C §1.5).
 *
 * Tokens / secrets go in `expo-secure-store` ONLY. AsyncStorage is
 * plaintext on disk — never store a token there, never in an
 * EXPO_PUBLIC_ variable, never in the bundle.
 *
 * The demo has NO auth and NO token exists yet (no sign-up wall before
 * the judge sees the product). These helpers exist so the first token,
 * if one ever appears, lands in the only correct place. Nothing in this
 * scaffold stores, reads, or ships a token today.
 */

import * as SecureStore from 'expo-secure-store';

/** Storage key for a future API/session token. No value is stored yet. */
export const TOKEN_KEY = 'hackathon:api-token';

export async function getToken(): Promise<string | null> {
  return SecureStore.getItemAsync(TOKEN_KEY);
}

export async function setToken(token: string): Promise<void> {
  await SecureStore.setItemAsync(TOKEN_KEY, token);
}

export async function deleteToken(): Promise<void> {
  await SecureStore.deleteItemAsync(TOKEN_KEY);
}
