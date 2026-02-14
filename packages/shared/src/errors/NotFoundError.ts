import { BaseError } from "./BaseError";

export class ElasticDashNotFoundError extends BaseError {
  constructor(description = "Not Found") {
    super("ElasticDashNotFoundError", 404, description, true);
  }
}
