#!/usr/bin/env node
import fs from "node:fs";
import { appendCapture } from "./lib.mjs";

function option(name) {
  const index = process.argv.indexOf(name);
  if (index === -1) return "";
  return process.argv[index + 1] || "";
}

const harness = option("--harness") || "unknown";
const event = option("--event") || "unknown";
const redactedOut = option("--redacted-out");
const raw = fs.readFileSync(0, "utf8");
const record = appendCapture(raw, { harness, event });
if (record.action === "capture.kept" && redactedOut) {
  fs.writeFileSync(redactedOut, JSON.stringify(record.redacted));
  process.exit(0);
}
process.exit(record.action === "capture.kept" ? 0 : 10);
