import { Inbox } from "lucide-react";
import Card from "../common/Card";
import EmptyState from "../common/EmptyState";
import { Skeleton } from "../common/Skeleton";

export default function AdminReportTable({ columns, rows, loading, emptyMessage = "Try adjusting your filters." }) {
  return (
    <Card className="overflow-x-auto animate-fade-slide-in" hover={false}>
      <table className="w-full text-sm">
        <thead>
          <tr className="text-left text-xs text-subtext uppercase border-b border-divider">
            {columns.map((col) => (
              <th key={col.key} className="px-4 py-3 whitespace-nowrap">
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {loading ? (
            Array.from({ length: 5 }).map((_, i) => (
              <tr key={i} className="border-b border-divider last:border-0">
                {columns.map((col) => (
                  <td key={col.key} className="px-4 py-3">
                    <Skeleton className="h-4 w-full" />
                  </td>
                ))}
              </tr>
            ))
          ) : rows.length === 0 ? (
            <tr>
              <td colSpan={columns.length}>
                <EmptyState icon={Inbox} title="No data found" message={emptyMessage} />
              </td>
            </tr>
          ) : (
            rows.map((row, i) => (
              <tr key={row._id || i} className="border-b border-divider last:border-0 hover:bg-soft-pink/30 transition-colors">
                {columns.map((col) => (
                  <td key={col.key} className="px-4 py-3 whitespace-nowrap">
                    {col.render ? col.render(row) : row[col.key] ?? "—"}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </Card>
  );
}
