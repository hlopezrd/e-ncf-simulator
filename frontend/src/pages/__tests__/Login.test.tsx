import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { AuthProvider } from "../../context/AuthContext";
import { Login } from "../Login";

const qc = new QueryClient();

function renderLogin() {
  return render(
    <QueryClientProvider client={qc}>
      <AuthProvider>
        <MemoryRouter>
          <Login />
        </MemoryRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}

describe("Login", () => {
  it("renders form fields", () => {
    renderLogin();
    expect(screen.getByText("Portal Administrativo")).toBeInTheDocument();
    expect(screen.getByPlaceholderText("101234567")).toBeInTheDocument();
    expect(screen.getByPlaceholderText("usuario-prueba")).toBeInTheDocument();
  });

  it("fills demo credentials", () => {
    renderLogin();
    fireEvent.click(screen.getByText("Usar credenciales de prueba"));
    expect(screen.getByDisplayValue("101234567")).toBeInTheDocument();
    expect(screen.getByDisplayValue("usuario-prueba")).toBeInTheDocument();
  });
});