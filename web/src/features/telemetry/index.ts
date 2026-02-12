import { logger } from "@elasticdash/shared/src/server";

export async function telemetry() {
  try {
    return;
  } catch (error) {
    // Catch all errors to be sure telemetry does not break the application
    logger.error("Telemetry, unexpected error:", error);
  }
}
