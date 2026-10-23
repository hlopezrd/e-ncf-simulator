import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { AuthProvider, useAuth } from "./context/AuthContext";
import { Layout } from "./components/Layout";
import { ProtectedRoute } from "./components/ProtectedRoute";
import { Login } from "./pages/Login";
import { Dashboard } from "./pages/Dashboard";
import { Placeholder } from "./pages/Placeholder";
import { Empresas } from "./pages/Empresas";
import { EcfList } from "./pages/EcfList";
import { Certificados } from "./pages/Certificados";
import { Validaciones } from "./pages/Validaciones";
import { EcfDetail } from "./pages/EcfDetail";
import { TrackIds } from "./pages/TrackIds";

const qc = new QueryClient();

function AppRoutes() {
  const { isAuthenticated } = useAuth();
  return (
    <Routes>
      <Route
        path="/login"
        element={isAuthenticated ? <Navigate to="/" replace /> : <Login />}
      />
      <Route
        path="/*"
        element={
          <ProtectedRoute>
            <Layout>
              <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/ecf" element={<EcfList />} />
                <Route path="/ecf/:trackId" element={<EcfDetail />} />
                <Route path="/trackids" element={<TrackIds />} />
                <Route path="/empresas" element={<Empresas />} />
                <Route path="/certificados" element={<Certificados />} />
                <Route path="/reglas" element={<Placeholder title="Reglas de simulación" />} />
                <Route path="/usuarios" element={<Placeholder title="Usuarios y roles" />} />
                <Route path="/validaciones" element={<Validaciones />} />
                <Route path="/auditoria" element={<Placeholder title="Auditoría" />} />
                <Route path="/configuracion" element={<Placeholder title="Configuración" />} />
                <Route path="/health" element={<Placeholder title="Salud del sistema" />} />
                <Route path="*" element={<Placeholder title="No encontrado" />} />
              </Routes>
            </Layout>
          </ProtectedRoute>
        }
      />
    </Routes>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={qc}>
      <AuthProvider>
        <BrowserRouter>
          <AppRoutes />
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}