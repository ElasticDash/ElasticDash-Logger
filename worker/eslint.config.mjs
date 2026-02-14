import baseConfig from "@repo/eslint-config";

export default [
  ...baseConfig,

  // Worker-specific ignores
  {
    name: "elasticdash/worker/ignores",
    ignores: ["**/*test*.*", "**/worker-thread.js"],
  },
];
