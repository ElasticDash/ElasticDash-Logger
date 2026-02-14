import { v5 } from "uuid";
import type {
  AnalyticsTraceEvent,
  AnalyticsGenerationEvent,
  AnalyticsScoreEvent,
} from "@elasticdash/shared/src/server";

// UUID v5 namespace for Mixpanel (different from PostHog)
const MIXPANEL_UUID_NAMESPACE = "8f7c3e42-9a1b-4d5f-8e2a-1c6b9d3f4e7a";

export type MixpanelEvent = {
  event: string;
  properties: {
    time: number; // milliseconds since epoch
    distinct_id: string;
    $insert_id: string;
    $user_id?: string;
    session_id?: string;
    [key: string]: unknown;
  };
};

export const transformTraceForMixpanel = (
  trace: AnalyticsTraceEvent,
  projectId: string,
): MixpanelEvent => {
  const insertId = v5(
    `${projectId}-${trace.elasticdash_id}`,
    MIXPANEL_UUID_NAMESPACE,
  );

  // Extract session IDs and exclude from properties

  const { posthog_session_id, mixpanel_session_id, ...otherProps } = trace;

  return {
    event: "[ElasticDash] Trace",
    properties: {
      time: new Date(trace.timestamp as Date).getTime(),
      distinct_id: trace.elasticdash_user_id
        ? (trace.elasticdash_user_id as string)
        : insertId,
      $insert_id: insertId,
      ...(trace.elasticdash_user_id
        ? { $user_id: trace.elasticdash_user_id as string }
        : {}),
      session_id:
        mixpanel_session_id || trace.elasticdash_session_id
          ? (mixpanel_session_id as string) ||
            (trace.elasticdash_session_id as string)
          : undefined,
      ...otherProps,
    },
  };
};

export const transformGenerationForMixpanel = (
  generation: AnalyticsGenerationEvent,
  projectId: string,
): MixpanelEvent => {
  const insertId = v5(
    `${projectId}-${generation.elasticdash_id}`,
    MIXPANEL_UUID_NAMESPACE,
  );

  // Extract session IDs and exclude from properties

  const { posthog_session_id, mixpanel_session_id, ...otherProps } = generation;

  return {
    event: "[ElasticDash] Generation",
    properties: {
      time: new Date(generation.timestamp as Date).getTime(),
      distinct_id: generation.elasticdash_user_id
        ? (generation.elasticdash_user_id as string)
        : insertId,
      $insert_id: insertId,
      ...(generation.elasticdash_user_id
        ? { $user_id: generation.elasticdash_user_id as string }
        : {}),
      session_id:
        mixpanel_session_id || generation.elasticdash_session_id
          ? (mixpanel_session_id as string) ||
            (generation.elasticdash_session_id as string)
          : undefined,
      ...otherProps,
    },
  };
};

export const transformScoreForMixpanel = (
  score: AnalyticsScoreEvent,
  projectId: string,
): MixpanelEvent => {
  const insertId = v5(
    `${projectId}-${score.elasticdash_id}`,
    MIXPANEL_UUID_NAMESPACE,
  );

  // Extract session IDs and exclude from properties

  const { posthog_session_id, mixpanel_session_id, ...otherProps } = score;

  return {
    event: "[ElasticDash] Score",
    properties: {
      time: new Date(score.timestamp as Date).getTime(),
      distinct_id: score.elasticdash_user_id
        ? (score.elasticdash_user_id as string)
        : insertId,
      $insert_id: insertId,
      ...(score.elasticdash_user_id
        ? { $user_id: score.elasticdash_user_id as string }
        : {}),
      session_id:
        mixpanel_session_id || score.elasticdash_session_id
          ? (mixpanel_session_id as string) ||
            (score.elasticdash_session_id as string)
          : undefined,
      ...otherProps,
    },
  };
};
