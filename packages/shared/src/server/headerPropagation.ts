import * as opentelemetry from "@opentelemetry/api";
import type { IncomingHttpHeaders } from "http";
import { env } from "../env";

export type ElasticDashContextProps = {
  headers?: IncomingHttpHeaders;
  userId?: string;
  projectId?: string;
};

/**
 * Returns a new context containing baggage entries composed from
 * the supplied props (headers, userId, projectId). Existing baggage
 * entries are preserved.
 */
export const contextWithElasticDashProps = (
  props: ElasticDashContextProps,
): opentelemetry.Context => {
  const ctx = opentelemetry.context.active();
  let baggage =
    opentelemetry.propagation.getBaggage(ctx) ??
    opentelemetry.propagation.createBaggage();

  if (props.headers) {
    (env.ELASTICDASH_LOG_PROPAGATED_HEADERS as string[]).forEach((name) => {
      const value = props.headers![name];
      if (!value) return;
      const strValue = Array.isArray(value) ? JSON.stringify(value) : value;
      baggage = baggage.setEntry(`elasticdash.header.${name}`, {
        value: strValue,
      });
    });

    // get x-elasticdash-xxx headers and add them to the span
    Object.keys(props.headers).forEach((name) => {
      if (
        name.toLowerCase().startsWith("x-elasticdash") ||
        name.toLowerCase().startsWith("x_elasticdash")
      ) {
        const value = props.headers![name];
        if (!value) return;
        const strValue = Array.isArray(value) ? JSON.stringify(value) : value;
        baggage = baggage.setEntry(`elasticdash.header.${name}`, {
          value: strValue,
        });
      }
    });
  }
  if (props.userId) {
    baggage = baggage.setEntry("elasticdash.user.id", { value: props.userId });
  }
  if (props.projectId) {
    baggage = baggage.setEntry("elasticdash.project.id", {
      value: props.projectId,
    });
  }

  return opentelemetry.propagation.setBaggage(ctx, baggage);
};
