import { type EvalTemplate } from "@elasticdash/shared";

// Define the type locally to match what's in @elasticdash/shared
type VariableMapping = {
  templateVariable: string;
  elasticdashObject: "trace" | "generation" | "span" | "score" | "dataset_item";
  objectName?: string;
  selectedColumnId: string;
  jsonSelector?: string;
};

const defaultMappings = new Map<string, Partial<VariableMapping>>([
  // Common input variables
  ["input", { elasticdashObject: "trace", selectedColumnId: "input" }],
  ["query", { elasticdashObject: "trace", selectedColumnId: "input" }],
  ["question", { elasticdashObject: "trace", selectedColumnId: "input" }],
  ["prompt", { elasticdashObject: "trace", selectedColumnId: "input" }],

  // Common output variables
  ["output", { elasticdashObject: "trace", selectedColumnId: "output" }],
  ["response", { elasticdashObject: "trace", selectedColumnId: "output" }],
  ["answer", { elasticdashObject: "trace", selectedColumnId: "output" }],
  ["completion", { elasticdashObject: "trace", selectedColumnId: "output" }],

  // Common ground truth variables
  [
    "expected_output",
    { elasticdashObject: "dataset_item", selectedColumnId: "expected_output" },
  ],
  [
    "ground_truth",
    { elasticdashObject: "dataset_item", selectedColumnId: "expected_output" },
  ],
  [
    "reference",
    { elasticdashObject: "dataset_item", selectedColumnId: "expected_output" },
  ],
]);

/**
 * Creates default variable mappings for an evaluator template.
 *
 * @param template - The evaluation template containing variables
 * @returns Array of variable mappings
 */
export function createDefaultVariableMappings(
  template: EvalTemplate,
): VariableMapping[] {
  if (!template.vars || template.vars.length === 0) {
    return [];
  }

  return template.vars.map((variable) => {
    // Check if we have a default mapping for this variable name
    const defaultMapping = defaultMappings.get(variable.toLowerCase());

    if (defaultMapping) {
      return {
        templateVariable: variable,
        elasticdashObject: defaultMapping.elasticdashObject || "dataset_item",
        selectedColumnId: defaultMapping.selectedColumnId || "expected_output",
        objectName: defaultMapping.objectName,
        jsonSelector: defaultMapping.jsonSelector,
      };
    }

    return {
      elasticdashObject: "dataset_item",
      templateVariable: variable,
      selectedColumnId: "expected_output",
    };
  });
}
