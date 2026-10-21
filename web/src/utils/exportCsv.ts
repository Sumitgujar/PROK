export type CsvValue = string | number | boolean | null | undefined;

export function downloadCsv(
  filename: string,
  rows: Array<Record<string, CsvValue>>,
): void {
  if (rows.length === 0) {
    window.alert("There is no data to export.");
    return;
  }

  const columns = Object.keys(rows[0]);
  const escapeCell = (value: CsvValue) => {
    const text = String(value ?? "");
    return '"' + text.replace(/"/g, '""') + '"';
  };

  const csv = [
    columns.map(escapeCell).join(","),
    ...rows.map((row) => columns.map((column) => escapeCell(row[column])).join(",")),
  ].join("\r\n");

  const blob = new Blob(["\uFEFF", csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}
