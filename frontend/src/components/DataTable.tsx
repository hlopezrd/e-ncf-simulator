import DataTableLib from "datatables.net-react";
import DT from "datatables.net-dt";
import { dtLanguage } from "../lib/dtLanguage";

DataTableLib.use(DT);

interface Col {
  title: string;
  data: string;
  render?: (d: any, type: any, row: any) => string;
  defaultContent?: string;
  orderable?: boolean;
}

interface Props {
  data: any[];
  columns: Col[];
  pageLength?: number;
  emptyTable?: string;
}

export function DataTable({ data, columns, pageLength = 10, emptyTable }: Props) {
  return (
    <DataTableLib
      data={data}
      columns={columns}
      className="display"
      options={{
        pageLength,
        language: { ...dtLanguage, emptyTable: emptyTable ?? dtLanguage.emptyTable },
        dom: "lfrtip",
      }}
    />
  );
}