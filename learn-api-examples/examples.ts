import { DefaultAzureCredential } from "@azure/identity";

const apiBaseUrl = "https://learn.microsoft.com/api/v1";
const apiVersion = "2023-11-01-preview";
const credential = new DefaultAzureCredential();
const maxRetryAttempts = 4;
const minRequestIntervalMs = 500;
const maxAutomaticWaitMs = 60_000;
let lastRequestStartedAt = 0;
const listResources = new Set([
  "courses",
  "learning-paths",
  "modules",
  "certifications",
  "exams",
  "applied-skills",
]);
const detailResources = new Set([...listResources, "units"]);
const allowedFilters = new Set([
  "levels",
  "roles",
  "products",
  "subjects",
  "locale",
  "maxpagesize",
  "maxitems",
]);

function printUsage(): void {
  console.log(`Microsoft Learn Platform API catalog

Usage:
  npm start -- <resource> [id] [--filter value ...]

Resources:
  courses, learning-paths, modules, units, certifications, exams, applied-skills

Examples:
  npm start -- certifications --levels beginner --products azure --maxpagesize 5
  npm start -- learning-paths --locale es-es --maxpagesize 5
  npm start -- learning-paths --maxpagesize 5 --maxitems 10
  npm start -- modules learn.wwl.fundamentals-generative-ai
  npm start -- units learn.wwl.fundamentals-generative-ai.agents

List requests follow every API page by default. Use --maxitems to cap the results.`);
}

function parseArguments(args: string[]): {
  resource?: string;
  id?: string;
  filters: Map<string, string>;
  maxItems?: number;
} {
  const filters = new Map<string, string>();
  let resource: string | undefined;
  let id: string | undefined;
  let maxItems: number | undefined;

  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];
    if (argument.startsWith("--")) {
      const name = argument.slice(2).toLowerCase();
      const value = args[index + 1];
      if (!allowedFilters.has(name)) {
        throw new Error(`Unknown filter: --${name}`);
      }
      if (!value || value.startsWith("--")) {
        throw new Error(`Filter --${name} requires a value.`);
      }
      if (name === "maxitems") {
        maxItems = Number(value);
        if (!Number.isInteger(maxItems) || maxItems < 1) {
          throw new Error("--maxitems must be a positive integer.");
        }
      } else {
        filters.set(name, value);
      }
      index += 1;
    } else if (!resource) {
      resource = argument.toLowerCase();
    } else if (!id) {
      id = argument;
    } else {
      throw new Error(`Unexpected argument: ${argument}`);
    }
  }

  return { resource, id, filters, maxItems };
}

async function getAccessToken(): Promise<string> {
  const token = await credential.getToken("https://learn.microsoft.com/.default");
  if (!token) {
    throw new Error("Could not acquire a Microsoft Learn API access token.");
  }
  return token.token;
}

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function getRetryAfterMilliseconds(response: Response): number | undefined {
  const retryAfter = response.headers.get("retry-after");
  if (!retryAfter) {
    return undefined;
  }

  const seconds = Number(retryAfter);
  if (Number.isFinite(seconds) && seconds >= 0) {
    return seconds * 1000;
  }

  const retryAt = Date.parse(retryAfter);
  return Number.isNaN(retryAt) ? undefined : Math.max(0, retryAt - Date.now());
}

async function fetchLearnApi(url: string, token: string): Promise<Response> {
  for (let attempt = 0; ; attempt += 1) {
    const elapsed = Date.now() - lastRequestStartedAt;
    if (lastRequestStartedAt > 0 && elapsed < minRequestIntervalMs) {
      await delay(minRequestIntervalMs - elapsed);
    }

    lastRequestStartedAt = Date.now();
    const response = await fetch(url, {
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
      },
    });

    if (![429, 503].includes(response.status) || attempt >= maxRetryAttempts) {
      return response;
    }

    const retryAfter = getRetryAfterMilliseconds(response);
    const backoff = Math.min(1000 * 2 ** attempt, maxAutomaticWaitMs);
    const waitMilliseconds = retryAfter ?? backoff;
    if (waitMilliseconds > maxAutomaticWaitMs) {
      throw new Error(
        `Learn API is rate limiting requests. Retry after ${Math.ceil(waitMilliseconds / 1000)} seconds.`,
      );
    }

    await response.body?.cancel();
    console.warn(
      `Learn API returned ${response.status}; retrying in ${Math.ceil(waitMilliseconds / 1000)} second(s) (${attempt + 1}/${maxRetryAttempts}).`,
    );
    await delay(waitMilliseconds);
  }
}

async function main(): Promise<void> {
  const { resource, id, filters, maxItems } = parseArguments(process.argv.slice(2));
  if (!resource) {
    printUsage();
    return;
  }

  if (id && !detailResources.has(resource)) {
    throw new Error(`Unsupported detail resource: ${resource}`);
  }
  if (!id && !listResources.has(resource)) {
    throw new Error(`Unsupported list resource: ${resource}`);
  }

  const params = new URLSearchParams({ "api-version": apiVersion });
  for (const [name, value] of filters) {
    params.set(name, value);
  }

  const resourcePath = id
    ? `${resource}/${id.split("/").map(encodeURIComponent).join("/")}`
    : resource;
  let nextUrl: string | undefined = `${apiBaseUrl}/${resourcePath}?${params.toString()}`;
  const token = await getAccessToken();
  const items: unknown[] = [];
  let pageCount = 0;
  let hasMore = false;

  while (nextUrl) {
    const response = await fetchLearnApi(nextUrl, token);

    if (!response.ok) {
      const details = await response.text();
      throw new Error(
        `Learn API returned ${response.status} ${response.statusText}${details ? `: ${details}` : ""}`,
      );
    }

    const body = await response.text();
    if (!body) {
      console.log("(empty response)");
      return;
    }

    let data: unknown;
    try {
      data = JSON.parse(body);
    } catch {
      throw new Error("The Learn API response was not valid JSON.");
    }

    if (id) {
      console.log(JSON.stringify(data, null, 2));
      return;
    }

    if (typeof data !== "object" || data === null) {
      throw new Error("The Learn API list response was not an object.");
    }

    const listResponse = data as { value?: unknown; nextLink?: unknown };
    if (!Array.isArray(listResponse.value)) {
      throw new Error("The Learn API list response did not contain a value array.");
    }

    const pageItems: unknown[] = listResponse.value;
    const remaining = maxItems === undefined ? pageItems.length : maxItems - items.length;
    items.push(...pageItems.slice(0, remaining));
    pageCount += 1;

    const link = typeof listResponse.nextLink === "string" ? listResponse.nextLink : undefined;
    if (maxItems !== undefined && items.length >= maxItems) {
      hasMore = Boolean(link);
      break;
    }

    if (link) {
      const parsedLink = new URL(link, apiBaseUrl);
      if (parsedLink.origin !== new URL(apiBaseUrl).origin) {
        throw new Error("The Learn API returned a nextLink outside the expected host.");
      }
      nextUrl = parsedLink.toString();
    } else {
      nextUrl = undefined;
    }
  }

  const rows = items.map((item) => {
    if (typeof item !== "object" || item === null) {
      return { Value: String(item) };
    }

    const record = item as Record<string, unknown>;
    const levels = Array.isArray(record.levels)
      ? record.levels
          .map((level) =>
            typeof level === "object" && level !== null && "id" in level
              ? String(level.id)
              : "",
          )
          .filter(Boolean)
          .join(", ")
      : "";

    return {
      Id: typeof record.id === "string" ? record.id : "",
      Title: typeof record.title === "string" ? record.title : "",
      Minutes: typeof record.durationInMinutes === "number" ? record.durationInMinutes : "",
      Levels: levels,
    };
  });

  console.table(rows);
  console.log(`Retrieved ${items.length} ${resource} item(s) across ${pageCount} page(s).`);
  if (hasMore) {
    console.log(`More results are available; increase or remove --maxitems to continue.`);
  }
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Error: ${message}`);
  process.exitCode = 1;
});