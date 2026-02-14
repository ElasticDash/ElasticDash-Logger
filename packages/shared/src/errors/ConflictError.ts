import { BaseError } from "./BaseError";

export class ElasticDashConflictError extends BaseError {
  constructor(description = "Conflict") {
    super("ElasticDashConflictError", 409, description, true);
  }
}
