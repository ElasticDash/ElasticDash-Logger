import { VERSION } from "@/src/constants/VERSION";
import { env } from "@/src/env.mjs";
import { createTRPCRouter, publicProcedure } from "@/src/server/api/trpc";
import { logger, compareVersions } from "@elasticdash/shared/src/server";
import { z } from "zod/v4";

const ReleaseApiRes = z.array(
  z.object({
    repo: z.string(),
    latestRelease: z.string(),
    publishedAt: z.string().datetime(),
    url: z.string().url(),
  }),
);

export const publicRouter = createTRPCRouter({
  checkUpdate: publicProcedure.query(async () => {
    // Skip update check on ElasticDash Cloud
    if (env.NEXT_PUBLIC_ELASTICDASH_CLOUD_REGION) return null;

    let body;
    try {
      const response = await fetch(
        `https://www.elasticdash.com/api/latest-releases?repo=elasticdash/elasticdash&version=${VERSION}`,
      );
      body = await response.json();
    } catch (error) {
      logger.error(
        "[trpc.public.checkUpdate] failed to fetch latest-release api",
        {
          error,
        },
      );
      return null;
    }

    const releases = ReleaseApiRes.safeParse(body);
    if (!releases.success) {
      logger.error(
        "[trpc.public.checkUpdate] Release API response is invalid, does not match schema",
        {
          error: releases.error,
        },
      );
      return null;
    }
    const elasticdashRelease = releases.data.find(
      (release) => release.repo === "elasticdash/elasticdash",
    );
    if (!elasticdashRelease) {
      logger.error(
        "[trpc.public.checkUpdate] Release API response is invalid, does not contain elasticdash/elasticdash",
      );
      return null;
    }

    const updateType = compareVersions(
      VERSION,
      elasticdashRelease.latestRelease,
    );

    return {
      updateType,
      currentVersion: VERSION,
      latestRelease: elasticdashRelease.latestRelease,
      url: elasticdashRelease.url,
    };
  }),
});
