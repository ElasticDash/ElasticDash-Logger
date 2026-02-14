// Standard analytics event types for analytics integrations (PostHog, Mixpanel, etc.)
// These represent the raw data structure from ClickHouse queries

export type AnalyticsTraceEvent = {
  elasticdash_id: unknown;
  timestamp: unknown;
  elasticdash_trace_name?: unknown;
  elasticdash_url?: unknown;
  elasticdash_user_url?: unknown;
  elasticdash_cost_usd?: unknown;
  elasticdash_count_observations?: unknown;
  elasticdash_session_id?: unknown;
  elasticdash_project_id?: unknown;
  elasticdash_user_id?: unknown;
  elasticdash_latency?: unknown;
  elasticdash_release?: unknown;
  elasticdash_version?: unknown;
  elasticdash_tags?: unknown;
  elasticdash_environment?: unknown;
  elasticdash_event_version?: unknown;
  posthog_session_id?: unknown;
  mixpanel_session_id?: unknown;
};

export type AnalyticsGenerationEvent = {
  elasticdash_id: unknown;
  timestamp: unknown;
  elasticdash_generation_name?: unknown;
  elasticdash_trace_name?: unknown;
  elasticdash_trace_id?: unknown;
  elasticdash_url?: unknown;
  elasticdash_user_url?: unknown;
  elasticdash_cost_usd?: unknown;
  elasticdash_input_units?: unknown;
  elasticdash_output_units?: unknown;
  elasticdash_total_units?: unknown;
  elasticdash_session_id?: unknown;
  elasticdash_project_id?: unknown;
  elasticdash_user_id?: unknown;
  elasticdash_latency?: unknown;
  elasticdash_time_to_first_token?: unknown;
  elasticdash_release?: unknown;
  elasticdash_version?: unknown;
  elasticdash_model?: unknown;
  elasticdash_level?: unknown;
  elasticdash_tags?: unknown;
  elasticdash_environment?: unknown;
  elasticdash_event_version?: unknown;
  posthog_session_id?: unknown;
  mixpanel_session_id?: unknown;
};

export type AnalyticsScoreEvent = {
  elasticdash_id: unknown;
  timestamp: unknown;
  elasticdash_score_name?: unknown;
  elasticdash_score_value?: unknown;
  elasticdash_score_comment?: unknown;
  elasticdash_score_metadata?: unknown;
  elasticdash_score_string_value?: unknown;
  elasticdash_score_data_type?: unknown;
  elasticdash_trace_name?: unknown;
  elasticdash_trace_id?: unknown;
  elasticdash_user_url?: unknown;
  elasticdash_session_id?: unknown;
  elasticdash_project_id?: unknown;
  elasticdash_user_id?: unknown;
  elasticdash_release?: unknown;
  elasticdash_tags?: unknown;
  elasticdash_environment?: unknown;
  elasticdash_event_version?: unknown;
  elasticdash_score_entity_type?: unknown;
  elasticdash_dataset_run_id?: unknown;
  posthog_session_id?: unknown;
  mixpanel_session_id?: unknown;
};
