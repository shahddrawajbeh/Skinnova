/**
 * Generates a CSV string from column definitions and data rows.
 * @param {Array<{key: string, label: string}>} columns
 * @param {Array<Object>} rows
 * @returns {string}
 */
function generateCsv(columns, rows) {
  const header = columns.map((c) => `"${c.label}"`).join(",");
  const data = rows.map((row) =>
    columns
      .map((c) => {
        const val = String(row[c.key] ?? "").replace(/"/g, '""');
        return `"${val}"`;
      })
      .join(",")
  );
  return [header, ...data].join("\n");
}

module.exports = { generateCsv };
