import { z } from "zod/v4";
import {
  singleFilter,
  type elasticdashObjects,
  TimeScopeSchema,
} from "@elasticdash/shared";
import { wipVariableMapping } from "@elasticdash/shared";

export const isTraceTarget = (target: string): boolean => target === "trace";
export const isTraceOrDatasetObject = (object: string): boolean =>
  object === "trace" || object === "dataset_item";

export const evalConfigFormSchema = z.object({
  scoreName: z.string(),
  target: z.string(),
  filter: z.array(singleFilter).nullable(), // reusing the filter type from the tables
  mapping: z.array(wipVariableMapping),
  sampling: z.coerce.number().gt(0).lte(1),
  delay: z.coerce.number().min(0).optional().default(10),
  timeScope: TimeScopeSchema,
});

export type EvalFormType = z.infer<typeof evalConfigFormSchema>;

export type ElasticDashObject = (typeof elasticdashObjects)[number];

export type VariableMapping = z.infer<typeof wipVariableMapping>;
