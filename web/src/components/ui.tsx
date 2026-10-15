import React from "react"

export function PageShell({ children }: { children: React.ReactNode }) {
  return <div className="space-y-6">{children}</div>
}

export function PageHeader({ title, sub }: { title: string; sub?: string }) {
  return (
    <div className="mb-6">
      <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
      {sub && <p className="text-sm text-gray-500 mt-1">{sub}</p>}
    </div>
  )
}

export function LoadingSpinner({ message = "Loading..." }: { message?: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 gap-3">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-900" />
      <p className="text-sm text-gray-500">{message}</p>
    </div>
  )
}

export function ErrorMessage({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="bg-red-50 border border-red-200 text-red-700 px-6 py-4 rounded-lg flex items-center justify-between">
      <span>{message}</span>
      {onRetry && (
        <button
          onClick={onRetry}
          className="ml-4 px-3 py-1 bg-red-600 text-white text-xs font-semibold rounded hover:bg-red-700 transition"
        >
          Retry
        </button>
      )}
    </div>
  )
}

export function EmptyState({ title, sub }: { title: string; sub?: string }) {
  return (
    <div className="text-center py-12 px-4 border-2 border-dashed border-gray-200 rounded-xl">
      <p className="text-base font-medium text-gray-700">{title}</p>
      {sub && <p className="text-xs text-gray-500 mt-1">{sub}</p>}
    </div>
  )
}

export function Badge({ status }: { status?: string }) {
  const s = (status || "").toUpperCase()
  let bg = "bg-gray-100 text-gray-700"
  if (s === "HIGH" || s === "REJECTED" || s === "OPEN") {
    bg = "bg-red-100 text-red-700 border border-red-200"
  } else if (s === "MEDIUM" || s === "UNDER_REVIEW" || s === "IN_PROGRESS" || s === "PENDING") {
    bg = "bg-amber-100 text-amber-700 border border-amber-200"
  } else if (s === "LOW" || s === "VERIFIED" || s === "RESOLVED" || s === "APPROVED") {
    bg = "bg-emerald-100 text-emerald-700 border border-emerald-200"
  }
  return (
    <span className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-semibold uppercase tracking-wider ${bg}`}>
      {status || "UNKNOWN"}
    </span>
  )
}

export function Card({
  children,
  style,
  className = "",
}: {
  children: React.ReactNode
  style?: React.CSSProperties
  className?: string
}) {
  return (
    <div
      style={style}
      className={`bg-white rounded-xl shadow-sm border border-gray-200 p-5 ${className}`}
    >
      {children}
    </div>
  )
}

export function StatCard({
  label,
  value,
  color,
}: {
  label: string
  value: string | number
  color?: string
}) {
  return (
    <div
      className="bg-white rounded-xl shadow-sm border border-gray-200 p-5"
      style={color ? { borderLeft: `4px solid ${color}` } : undefined}
    >
      <p className="text-xs font-medium text-gray-500 uppercase tracking-wider">{label}</p>
      <p className="text-2xl font-bold text-gray-900 mt-1" style={color ? { color } : undefined}>
        {value}
      </p>
    </div>
  )
}
