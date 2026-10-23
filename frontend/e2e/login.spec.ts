import { test, expect } from "@playwright/test";

test("login with demo credentials", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByText("Portal Administrativo")).toBeVisible();

  await page.getByRole("button", { name: "Usar credenciales de prueba" }).click();
  await page.getByRole("button", { name: "Ingresar" }).click();

  await expect(page.getByText("Dashboard")).toBeVisible();
});

test("navigate to e-CF page", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("button", { name: "Usar credenciales de prueba" }).click();
  await page.getByRole("button", { name: "Ingresar" }).click();

  await page.getByRole("link", { name: "e-CF" }).click();
  await expect(page.getByText("e-CF")).toBeVisible();
});