import { useQuery } from "@tanstack/react-query";
import DataTable from "datatables.net-react";
import DT from "datatables.net-dt";
import { empresasApi } from "../lib/api";

DataTable.use(DT);

export function Empresas() {
  const { data, isLoading, error } = useQuery({
    queryKey: ["empresas"],
    queryFn: empresasApi.list,
  });

  const columns = [
    { title: "RNC Emisor", data: "rnc" },
    { title: "Total e-CF", data: "totalEcf" },
    { title: "Última recepción", data: "ultimaRecepcion", defaultContent: "—" },
  ];

  return (
    <div>
      <h1 style={{ marginBottom: "var(--space-5)" }}>Empresas y RNC</h1>
      {isLoading && <div className="skeleton" style={{ height: 200 }} />}
      {error && <p style={{ color: "var(--color-danger)" }}>Error al cargar empresas</p>}
      {data && (
        <DataTable
          data={data.data}
          columns={columns}
          className="display"
          options={{ pageLength: 10, language: { emptyTable: "Sin datos" } }}
        />
      )}
    </div>
  );
}