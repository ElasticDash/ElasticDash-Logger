import { v5 } from "uuid";
import type {
  AnalyticsTraceEvent,
  AnalyticsGenerationEvent,
  AnalyticsScoreEvent,
} from "@elasticdash/shared/src/server";

// UUID v5 namespace for PostHog
const POSTHOG_UUID_NAMESPACE = "0f6c91df-d035-4813-b838-9741ba38ef0b";

type PostHogEvent = {
  distinctId: string;
  event: string;
  properties: Record<string, unknown>;
  timestamp: Date;
  uuid: string;
};

export const transformTraceForPostHog = (
  trace: AnalyticsTraceEvent,
  projectId: string,
): PostHogEvent => {
  const uuid = v5(
    `${projectId}-${trace.elasticdash_id}`,
    POSTHOG_UUID_NAMESPACE,
  );

  // Extract posthog_session_id and map to $session_id

  const { posthog_session_id, mixpanel_session_id, ...otherProps } = trace;

  return {
    distinctId: trace.elasticdash_user_id
      ? (trace.elasticdash_user_id as string)
      : uuid,
    event: "elasticdash trace",
    properties: {
      ...otherProps,
      $session_id: posthog_session_id ?? null,
      // PostHog-specific: add user profile enrichment or mark as anonymous
      ...(trace.elasticdash_user_id && trace.elasticdash_user_url
        ? {
            $set: {
              elasticdash_user_url: trace.elasticdash_user_url,
            },
          }
        : // Capture as anonymous PostHog event (cheaper/faster)
          // https://posthog.com/docs/data/anonymous-vs-identified-events?tab=Backend
          { $process_person_profile: false }),
    },
    timestamp: trace.timestamp as Date,
    uuid,
  };
};

export const transformGenerationForPostHog = (
  generation: AnalyticsGenerationEvent,
  projectId: string,
): PostHogEvent => {
  const uuid = v5(
    `${projectId}-${generation.elasticdash_id}`,
    POSTHOG_UUID_NAMESPACE,
  );

  // Extract posthog_session_id and map to $session_id

  const { posthog_session_id, mixpanel_session_id, ...otherProps } = generation;

  return {
    distinctId: generation.elasticdash_user_id
      ? (generation.elasticdash_user_id as string)
      : uuid,
    event: "elasticdash generation",
    properties: {
      ...otherProps,
      $session_id: posthog_session_id ?? null,
      // PostHog-specific: add user profile enrichment or mark as anonymous
      ...(generation.elasticdash_user_id && generation.elasticdash_user_url
        ? {
            $set: {
              elasticdash_user_url: generation.elasticdash_user_url,
            },
          }
        : // Capture as anonymous PostHog event (cheaper/faster)
          // https://posthog.com/docs/data/anonymous-vs-identified-events?tab=Backend
          { $process_person_profile: false }),
    },
    timestamp: generation.timestamp as Date,
    uuid,
  };
};

export const transformScoreForPostHog = (
  score: AnalyticsScoreEvent,
  projectId: string,
): PostHogEvent => {
  const uuid = v5(
    `${projectId}-${score.elasticdash_id}`,
    POSTHOG_UUID_NAMESPACE,
  );

  // Extract posthog_session_id and map to $session_id

  const { posthog_session_id, mixpanel_session_id, ...otherProps } = score;

  return {
    distinctId: score.elasticdash_user_id
      ? (score.elasticdash_user_id as string)
      : uuid,
    event: "elasticdash score",
    properties: {
      ...otherProps,
      $session_id: posthog_session_id ?? null,
      // PostHog-specific: add user profile enrichment or mark as anonymous
      ...(score.elasticdash_user_id && score.elasticdash_user_url
        ? {
            $set: {
              elasticdash_user_url: score.elasticdash_user_url,
            },
          }
        : // Capture as anonymous PostHog event (cheaper/faster)
          // https://posthog.com/docs/data/anonymous-vs-identified-events?tab=Backend
          { $process_person_profile: false }),
    },
    timestamp: score.timestamp as Date,
    uuid,
  };
};
