import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { AuthProvider, useAuth } from "./context/AuthContext";
import { lazy, Suspense } from "react";
import { Layout } from "./components/Layout";
import { ProtectedRoute } from "./components/ProtectedRoute";
import { Login } from "./pages/Login";
import { Dashboard } from "./pages/Dashboard";
const Placeholder = lazy(() => import("./pages/Placeholder").then((m) => ({ default: m.Placeholder })));
const Empresas = lazy(() => import("./pages/Empresas").then((m) => ({ default: m.Empresas })));
const EcfList = lazy(() => import("./pages/EcfList").then((m) => ({ default: m.EcfList })));
const EcfDetail = lazy(() => import("./pages/EcfDetail").then((m) => ({ default: m.EcfDetail })));
const TrackIds = lazy(() => import("./pages/TrackIds").then((m) => ({ default: m.TrackIds })));
const Certificados = lazy(() => import("./pages/Certificados").then((m) => ({ default: m.Certificados })));
const NcfSequences = lazy(() => import("./pages/NcfSequences").then((m) => ({ default: m.NcfSequences })));
const Validaciones = lazy(() => import("./pages/Validaciones").then((m) => ({ default: m.Validaciones })));
const Reglas = lazy(() => import("./pages/Reglas").then((m) => ({ default: m.Reglas })));
const AllowedOrigins = lazy(() => import("./pages/AllowedOrigins").then((m) => ({ default: m.AllowedOrigins })));
const Usuarios = lazy(() => import("./pages/Usuarios").then((m) => ({ default: m.Usuarios })));
const Auditoria = lazy(() => import("./pages/Auditoria").then((m) => ({ default: m.Auditoria })));
const Guia = lazy(() => import("./pages/Guia").then((m) => ({ default: m.Guia })));

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
              <Suspense fallback={<div className="skeleton" style={{ height: 200, margin: "var(--space-5)" }} />}>
                <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/ecf" element={<EcfList />} />
                <Route path="/ecf/:trackId" element={<EcfDetail />} />
                <Route path="/trackids" element={<TrackIds />} />
                <Route path="/empresas" element={<Empresas />} />
                <Route path="/certificados" element={<Certificados />} />
<Route path="/ncf-sequences" element={<NcfSequences />} />
                <Route path="/reglas" element={<Reglas />} />
                <Route path="/cors" element={<AllowedOrigins />} />
                <Route path="/usuarios" element={<Usuarios />} />
                <Route path="/validaciones" element={<Validaciones />} />
                <Route path="/auditoria" element={<Auditoria />} />
                <Route path="/configuracion" element={<Placeholder title="Configuración" />} />
                <Route path="/health" element={<Placeholder title="Salud del sistema" />} />
                <Route path="/guia" element={<Guia />} />
                <Route path="*" element={<Placeholder title="No encontrado" />} />
              </Routes>
              </Suspense>
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