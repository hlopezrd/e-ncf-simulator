# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: login.spec.ts >> navigate to e-CF page
- Location: e2e/login.spec.ts:13:1

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: getByText('e-CF')
Expected: visible
Error: strict mode violation: getByText('e-CF') resolved to 5 elements:
    1) <div>e-CF Admin</div> aka getByText('e-CF Admin')
    2) <a class="" href="/ecf" data-discover="true">e-CF</a> aka getByRole('link', { name: 'e-CF' })
    3) <strong>Simulador e-CF (DGII RD)</strong> aka getByText('Simulador e-CF (DGII RD)')
    4) <span>Total e-CF</span> aka getByText('Total e-CF')
    5) <span>e-cf-simulator — 2026-10-23T18:37:59Z</span> aka getByText('e-cf-simulator — 2026-10-')

Call log:
  - Expect "toBeVisible" getByText('e-CF') with timeout 5000ms
  - waiting for getByText('e-CF')

```

# Page snapshot

```yaml
- generic [ref=e3]:
  - complementary [ref=e4]:
    - generic [ref=e5]:
      - generic [ref=e6]: e
      - generic [ref=e7]:
        - generic [ref=e8]: e-CF Admin
        - generic [ref=e9]: Simulador DGII RD
    - link "Dashboard" [ref=e10] [cursor=pointer]:
      - /url: /
    - link "e-CF" [active] [ref=e11] [cursor=pointer]:
      - /url: /ecf
    - link "TrackIds" [ref=e12] [cursor=pointer]:
      - /url: /trackids
    - link "Empresas" [ref=e13] [cursor=pointer]:
      - /url: /empresas
    - link "Certificados" [ref=e14] [cursor=pointer]:
      - /url: /certificados
    - link "Validaciones" [ref=e15] [cursor=pointer]:
      - /url: /validaciones
    - link "Reglas" [ref=e16] [cursor=pointer]:
      - /url: /reglas
    - link "CORS" [ref=e17] [cursor=pointer]:
      - /url: /cors
    - link "Usuarios" [ref=e18] [cursor=pointer]:
      - /url: /usuarios
    - link "Auditoría" [ref=e19] [cursor=pointer]:
      - /url: /auditoria
    - link "Configuración" [ref=e20] [cursor=pointer]:
      - /url: /configuracion
    - link "Salud" [ref=e21] [cursor=pointer]:
      - /url: /health
    - button "Salir" [ref=e22] [cursor=pointer]
  - generic [ref=e23]:
    - banner [ref=e24]:
      - strong [ref=e25]: Simulador e-CF (DGII RD)
      - generic [ref=e26]: Entorno de simulación — sin validez fiscal
    - main [ref=e27]:
      - generic [ref=e28]:
        - heading "Dashboard" [level=1] [ref=e29]
        - generic [ref=e30]:
          - generic [ref=e31]:
            - generic [ref=e32]:
              - generic [ref=e33]: Total e-CF
              - generic [ref=e34]: 📄
            - generic [ref=e35]: …
          - generic [ref=e36]:
            - generic [ref=e37]:
              - generic [ref=e38]: Aceptados
              - generic [ref=e39]: ✅
            - generic [ref=e40]: …
          - generic [ref=e41]:
            - generic [ref=e42]:
              - generic [ref=e43]: Rechazados
              - generic [ref=e44]: ❌
            - generic [ref=e45]: …
          - generic [ref=e46]:
            - generic [ref=e47]:
              - generic [ref=e48]: Condicionales
              - generic [ref=e49]: ⚠️
            - generic [ref=e50]: …
        - generic [ref=e51]:
          - heading "Estado del sistema" [level=3] [ref=e52]
          - paragraph [ref=e53]:
            - generic [ref=e54]: ok
            - generic [ref=e55]: e-cf-simulator — 2026-10-23T18:37:59Z
```

# Test source

```ts
  1  | import { test, expect } from "@playwright/test";
  2  | 
  3  | test("login with demo credentials", async ({ page }) => {
  4  |   await page.goto("/");
  5  |   await expect(page.getByText("Portal Administrativo")).toBeVisible();
  6  | 
  7  |   await page.getByRole("button", { name: "Usar credenciales de prueba" }).click();
  8  |   await page.getByRole("button", { name: "Ingresar" }).click();
  9  | 
  10 |   await expect(page.getByText("Dashboard")).toBeVisible();
  11 | });
  12 | 
  13 | test("navigate to e-CF page", async ({ page }) => {
  14 |   await page.goto("/");
  15 |   await page.getByRole("button", { name: "Usar credenciales de prueba" }).click();
  16 |   await page.getByRole("button", { name: "Ingresar" }).click();
  17 | 
  18 |   await page.getByRole("link", { name: "e-CF" }).click();
> 19 |   await expect(page.getByText("e-CF")).toBeVisible();
     |                                        ^ Error: expect(locator).toBeVisible() failed
  20 | });
```