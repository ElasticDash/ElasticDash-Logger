import { upsertDefaultModelPrices } from "./scripts/upsertDefaultModelPrices";
import { upsertManagedEvaluators } from "./scripts/upsertManagedEvaluators";
import { upsertElasticDashDashboards } from "./scripts/upsertElasticDashDashboards";

upsertDefaultModelPrices();
upsertManagedEvaluators();
upsertElasticDashDashboards();
