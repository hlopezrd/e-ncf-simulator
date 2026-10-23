import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  use: {
    baseURL: "http://localhost:5173",
    headless: true,
  },
  webServer: [
    {
      command: "bin/rails server -p 13000",
      url: "http://localhost:13000/health",
      reuseExistingServer: true,
      timeout: 60_000,
      cwd: "..",
    },
    {
      command: "yarn dev",
      url: "http://localhost:5173",
      reuseExistingServer: true,
      timeout: 60_000,
    },
  ],
});