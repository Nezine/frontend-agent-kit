/**
 * ai-demo.tsx — verification screen for the D53/D54/D55 scaffold.
 *
 * Demonstrates (idea-agnostic — no product idea is chosen yet):
 * - theme.ts tokens (colours, spacing, radius, type, layout, fontScaling)
 * - useColorScheme + userInterfaceStyle: automatic (app.json)
 * - safe-area insets via useSafeAreaInsets() (no hardcoded notch numbers)
 * - font-scaling caps via theme.fontScaling (body uncapped, button 1.5)
 * - network status + offline banner (useNetworkStatus, verbatim template)
 * - Zustand draft persistence + lastResultId pointer (no result JSON in Zustand)
 * - Stub AI run → rung A1 "Example result" (no network, no key, no URL)
 * - Last good from the TanStack persisted cache → rung A2 "Cached — from <time>"
 * - Bundled seed JSON → rung A3 "Offline demo data"
 * - Offline queued prompt (AsyncStorage, QUEUED_PROMPT_KEY) — offered as
 *   "Back online — Run now?", never auto-fired.
 *
 * Reachable at /ai-demo (deep link: mobilescaffold://ai-demo in a build,
 * exp://<metro-host>:8081/--/ai-demo in Expo Go).
 */

import { useEffect, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import AsyncStorage from '@react-native-async-storage/async-storage';

import { useColorScheme } from '@/components/useColorScheme';
import {
  getA1Result,
  getA2Result,
  getA3Result,
  getSeedRecords,
  runAiStub,
  type AiResult,
  type RungResult,
} from '@/lib/ai';
import { LAST_RESULT_KEY, queryKeys } from '@/lib/query-client';
import { useAppStore } from '@/lib/store';
import { fontScaling, layout, radius, spacing, theme, type } from '@/lib/theme';
import { offlineBannerText, QUEUED_PROMPT_KEY, useNetworkStatus } from '@/lib/use-network-status';

export default function AiDemoScreen() {
  const scheme = useColorScheme();
  const colors = theme.colors[scheme];
  const insets = useSafeAreaInsets();
  const { isOnline, type: netType } = useNetworkStatus();
  const queryClient = useQueryClient();

  const draftInput = useAppStore((s) => s.draftInput);
  const setDraftInput = useAppStore((s) => s.setDraftInput);
  const lastResultId = useAppStore((s) => s.lastResultId);
  const setLastResultId = useAppStore((s) => s.setLastResultId);
  const isGenerating = useAppStore((s) => s.isGenerating);
  const setIsGenerating = useAppStore((s) => s.setIsGenerating);
  const streamError = useAppStore((s) => s.streamError);
  const setStreamError = useAppStore((s) => s.setStreamError);

  const [shown, setShown] = useState<RungResult | null>(null);
  const [queuedPrompt, setQueuedPrompt] = useState<string | null>(null);
  const [showSeed, setShowSeed] = useState(false);

  // Durable non-AI mutation — mutationFn comes from the module-load
  // default registered in lib/query-client.ts (['save-result']).
  const saveResult = useMutation<string, Error, { id: string; payload: AiResult }>({
    mutationKey: ['save-result'],
  });

  // On mount: restore the last good result from the persisted cache (A2).
  useEffect(() => {
    if (!lastResultId) return;
    const cached = queryClient.getQueryData<AiResult>(queryKeys.aiResult(lastResultId));
    if (cached) {
      void AsyncStorage.getItem(LAST_RESULT_KEY).then((raw) => {
        const savedAt = raw ? (JSON.parse(raw) as { savedAt: string }).savedAt : cached.createdAt;
        setShown(getA2Result(cached, savedAt));
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lastResultId]);

  // On mount: read any queued offline prompt (never auto-fired).
  useEffect(() => {
    void AsyncStorage.getItem(QUEUED_PROMPT_KEY).then(setQueuedPrompt);
  }, []);

  const runStub = async (input: string) => {
    if (isGenerating) return; // C3: no double-submit for one tap
    setIsGenerating(true);
    setStreamError(null);
    try {
      const result = await runAiStub(input);
      const id = `stub-${Date.now()}`;
      const stored: AiResult = { ...result, id };
      queryClient.setQueryData(queryKeys.aiResult(id), stored);
      setLastResultId(id);
      saveResult.mutate({ id, payload: stored });
      setShown(getA1Result(input));
    } catch (error) {
      setStreamError(error instanceof Error ? error.message : 'Stub failed.');
    } finally {
      setIsGenerating(false);
    }
  };

  const onGenerate = async () => {
    if (!isOnline) {
      // Offline: do NOT fire. Queue the prompt text locally and explain.
      await AsyncStorage.setItem(QUEUED_PROMPT_KEY, draftInput);
      setQueuedPrompt(draftInput);
      setStreamError('Needs connection — your draft is saved.');
      return;
    }
    await runStub(draftInput);
  };

  const runQueuedNow = async () => {
    const prompt = queuedPrompt ?? '';
    await AsyncStorage.removeItem(QUEUED_PROMPT_KEY);
    setQueuedPrompt(null);
    setDraftInput(prompt);
    await runStub(prompt);
  };

  return (
    <ScrollView
      style={[styles.container, { backgroundColor: colors.background }]}
      contentContainerStyle={{
        paddingHorizontal: spacing.lg,
        paddingTop: Math.max(insets.top, spacing.md),
        paddingBottom: Math.max(insets.bottom, spacing.md),
        gap: spacing.lg,
      }}
    >
      <Text
        style={[type.title, { color: colors.text }]}
        maxFontSizeMultiplier={fontScaling.body}
      >
        AI demo (scaffold)
      </Text>

      {!isOnline && (
        <View style={[styles.banner, { backgroundColor: colors.brandSoft, borderRadius: radius.md }]}>
          <Text style={[type.bodySmall, { color: colors.text }]} maxFontSizeMultiplier={fontScaling.body}>
            {offlineBannerText(netType)}
          </Text>
        </View>
      )}

      <TextInput
        style={[
          styles.input,
          {
            color: colors.text,
            borderColor: colors.border,
            borderRadius: radius.md,
            padding: spacing.md,
          },
        ]}
        value={draftInput}
        onChangeText={setDraftInput}
        placeholder="Type the demo input…"
        placeholderTextColor={colors.textSecondary}
        maxFontSizeMultiplier={fontScaling.body}
        accessibilityLabel="Demo input"
      />

      <Pressable
        onPress={onGenerate}
        disabled={isGenerating}
        accessibilityRole="button"
        accessibilityState={{ busy: isGenerating, disabled: isGenerating }}
        accessibilityLabel={isGenerating ? 'Thinking' : 'Generate'}
        style={[
          styles.cta,
          {
            backgroundColor: colors.brand,
            borderRadius: radius.md,
            minHeight: layout.ctaHeightMin,
            opacity: isGenerating ? 0.6 : 1,
          },
        ]}
      >
        <Text
          style={[type.body, { color: colors.textInverse, fontWeight: '600', textAlign: 'center' }]}
          maxFontSizeMultiplier={fontScaling.button}
        >
          {isGenerating ? 'Thinking…' : 'Generate (stub)'}
        </Text>
      </Pressable>

      {streamError && (
        <View style={[styles.card, { backgroundColor: colors.surface, borderRadius: radius.md }]}>
          <Text style={[type.bodySmall, { color: colors.error }]} maxFontSizeMultiplier={fontScaling.body}>
            {streamError}
          </Text>
        </View>
      )}

      {queuedPrompt !== null && isOnline && (
        <Pressable
          onPress={runQueuedNow}
          accessibilityRole="button"
          accessibilityLabel="Back online — Run now?"
          style={[styles.cta, { backgroundColor: colors.surfaceRaised, borderRadius: radius.md, minHeight: layout.tapTargetMin }]}
        >
          <Text style={[type.body, { color: colors.text, textAlign: 'center' }]} maxFontSizeMultiplier={fontScaling.button}>
            Back online — Run now?
          </Text>
        </Pressable>
      )}

      {shown && (
        <View style={[styles.card, { backgroundColor: colors.surface, borderRadius: radius.md }]}>
          <Text style={[type.caption, { color: colors.textSecondary }]} maxFontSizeMultiplier={fontScaling.chip}>
            {shown.label} · rung {shown.rung}
          </Text>
          <Text style={[type.headline, { color: colors.text }]} maxFontSizeMultiplier={fontScaling.body}>
            {shown.result.title}
          </Text>
          <Text style={[type.body, { color: colors.text }]} maxFontSizeMultiplier={fontScaling.body}>
            {shown.result.summary}
          </Text>
        </View>
      )}

      <Pressable
        onPress={() => setShowSeed((v) => !v)}
        accessibilityRole="button"
        accessibilityLabel="Toggle offline demo data"
        style={[styles.cta, { backgroundColor: colors.surfaceRaised, borderRadius: radius.md, minHeight: layout.tapTargetMin }]}
      >
        <Text style={[type.body, { color: colors.text, textAlign: 'center' }]} maxFontSizeMultiplier={fontScaling.button}>
          {showSeed ? 'Hide offline demo data (A3)' : 'Show offline demo data (A3)'}
        </Text>
      </Pressable>

      {showSeed && (
        <View style={[styles.card, { backgroundColor: colors.surface, borderRadius: radius.md }]}>
          <Text style={[type.caption, { color: colors.textSecondary }]} maxFontSizeMultiplier={fontScaling.chip}>
            Offline demo data · rung A3
          </Text>
          {getSeedRecords().map((record) => (
            <Text key={record.id} style={[type.bodySmall, { color: colors.text }]} maxFontSizeMultiplier={fontScaling.body}>
              {record.title} — {record.detail}
            </Text>
          ))}
          <Text style={[type.bodySmall, { color: colors.textSecondary }]} maxFontSizeMultiplier={fontScaling.body}>
            {getA3Result().result.summary}
          </Text>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  banner: { padding: spacing.md },
  input: { borderWidth: 1, fontSize: 16, lineHeight: 24 },
  cta: { justifyContent: 'center', paddingHorizontal: spacing.lg },
  card: { padding: spacing.lg, gap: spacing.sm },
});
