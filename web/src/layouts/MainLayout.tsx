import { useEffect, useMemo, useRef, useState, type FormEvent } from "react"
import { Outlet, NavLink, useLocation, useNavigate } from "react-router-dom"
import { useAuth } from "../hooks/useAuth"

const NAV = [
  { to: "/dashboard", label: "Dashboard", emoji: "📊", hint: "Platform summary" },
  { to: "/overview", label: "Overview", emoji: "🎯", hint: "Operational overview" },
  { to: "/students", label: "Students", emoji: "🎓", hint: "Student directory" },
  { to: "/attendance", label: "Attendance", emoji: "📋", hint: "Attendance sessions" },
  { to: "/documents", label: "Documents", emoji: "📄", hint: "Document review" },
  { to: "/scholarships", label: "Scholarships", emoji: "🏆", hint: "Application decisions" },
  { to: "/courses", label: "Courses", emoji: "📚", hint: "Course catalogue" },
  { to: "/interventions", label: "Interventions", emoji: "🛡️", hint: "Student support cases" },
  { to: "/ai-insights", label: "AI Insights", emoji: "🤖", hint: "Risk and matching insights" },
  { to: "/reports", label: "Reports", emoji: "📈", hint: "Analytics and exports" },
]

export default function MainLayout() {
  const { logout, user } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const searchRef = useRef<HTMLInputElement>(null)
  const [mobileNavOpen, setMobileNavOpen] = useState(false)
  const [search, setSearch] = useState("")
  const [searchFocused, setSearchFocused] = useState(false)
  const activePage = NAV.find(item => item.to === location.pathname) ?? NAV[0]
  const results = useMemo(() => {
    const query = search.trim().toLowerCase()
    if (!query) return []
    return NAV.filter(item => (item.label + " " + item.hint).toLowerCase().includes(query)).slice(0, 5)
  }, [search])

  useEffect(() => {
    setMobileNavOpen(false)
    setSearchFocused(false)
  }, [location.pathname])

  useEffect(() => {
    const handleShortcut = (event: KeyboardEvent) => {
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k") {
        event.preventDefault()
        searchRef.current?.focus()
        setSearchFocused(true)
      }
      if (event.key === "Escape") {
        setSearchFocused(false)
        setSearch("")
        searchRef.current?.blur()
      }
    }
    window.addEventListener("keydown", handleShortcut)
    return () => window.removeEventListener("keydown", handleShortcut)
  }, [])

  const signOut = () => {
    logout()
    navigate("/login")
  }

  const openFirstResult = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (results[0]) {
      navigate(results[0].to)
      setSearch("")
      setSearchFocused(false)
    }
  }

  const searchBox = (mobile = false) => (
    <form onSubmit={openFirstResult} className={mobile ? "relative sm:hidden" : "relative hidden w-full max-w-sm sm:block"}>
      <label className="sr-only" htmlFor={mobile ? "prok-mobile-search" : "prok-navigation-search"}>Search dashboard pages</label>
      <input
        id={mobile ? "prok-mobile-search" : "prok-navigation-search"}
        ref={mobile ? undefined : searchRef}
        value={search}
        onChange={event => setSearch(event.target.value)}
        onFocus={() => setSearchFocused(true)}
        onBlur={() => window.setTimeout(() => setSearchFocused(false), 140)}
        placeholder={mobile ? "Search dashboard pages…" : "Jump to a page…"}
        autoComplete="off"
        className={"w-full rounded-xl border border-slate-200 bg-slate-50 py-2.5 px-3 text-sm outline-none transition focus:border-blue-400 focus:bg-white focus:ring-4 focus:ring-blue-50 " + (!mobile ? "pr-16 pl-9" : "")}
      />
      {!mobile && <span aria-hidden="true" className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">⌕</span>}
      {!mobile && <span className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 rounded border border-slate-200 bg-white px-1.5 py-0.5 text-[10px] font-semibold text-slate-400">Ctrl K</span>}
      {searchFocused && search.trim() && (
        <div className="absolute left-0 right-0 top-full z-50 mt-2 overflow-hidden rounded-xl border border-slate-200 bg-white p-1 shadow-xl">
          {results.length ? results.map(item => (
            <button key={item.to} type="button" onMouseDown={event => event.preventDefault()} onClick={() => { navigate(item.to); setSearch(""); setSearchFocused(false) }}
              className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left hover:bg-blue-50">
              <span className="text-lg">{item.emoji}</span>
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-semibold text-slate-800">{item.label}</span>
                <span className="block truncate text-xs text-slate-500">{item.hint}</span>
              </span>
              <span className="text-xs text-slate-400">↵</span>
            </button>
          )) : <p className="px-3 py-4 text-sm text-slate-500">No dashboard pages match “{search}”.</p>}
        </div>
      )}
    </form>
  )

  return (
    <div className="flex h-screen overflow-hidden bg-slate-50 text-slate-800">
      {mobileNavOpen && <button aria-label="Close navigation menu" onClick={() => setMobileNavOpen(false)} className="fixed inset-0 z-30 bg-slate-950/50 lg:hidden" />}
      <aside className={"fixed inset-y-0 left-0 z-40 flex w-64 flex-shrink-0 flex-col bg-slate-950 text-white shadow-xl transition-transform duration-200 lg:static lg:translate-x-0 " + (mobileNavOpen ? "translate-x-0" : "-translate-x-full")}>
        <div className="border-b border-white/10 px-5 py-6">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-500 text-lg font-black shadow-lg shadow-blue-500/25">P</div>
            <div><div className="text-xl font-bold tracking-tight">PROK</div><div className="text-xs font-medium uppercase tracking-[0.18em] text-blue-300">Admin workspace</div></div>
          </div>
          <div className="mt-5 truncate rounded-lg bg-white/5 px-3 py-2 text-sm text-slate-300">Signed in as <span className="font-semibold text-white">{user?.full_name || user?.name || user?.email || "Admin"}</span></div>
        </div>
        <nav aria-label="Primary navigation" className="flex-1 space-y-1 overflow-y-auto p-3">
          <p className="px-3 pb-2 pt-1 text-[10px] font-bold uppercase tracking-[0.2em] text-slate-500">Workspace</p>
          {NAV.map(item => (
            <NavLink key={item.to} to={item.to} title={item.hint}
              className={({ isActive }) => "group flex items-center gap-3 rounded-xl px-3 py-3 text-sm font-medium transition-colors " + (isActive ? "bg-blue-600 text-white shadow-lg shadow-blue-950/30" : "text-slate-300 hover:bg-white/10 hover:text-white")}>
              <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-white/5 text-base group-hover:bg-white/10">{item.emoji}</span>
              <span className="flex-1">{item.label}</span>
              {location.pathname === item.to && <span className="h-1.5 w-1.5 rounded-full bg-white" />}
            </NavLink>
          ))}
        </nav>
        <div className="border-t border-white/10 p-3">
          <div className="mb-2 rounded-xl bg-gradient-to-br from-blue-500/20 to-indigo-500/10 p-3">
            <p className="text-xs font-semibold text-blue-200">MANAGE · GUIDE · SUPPORT · GROW</p>
            <p className="mt-1 text-[11px] leading-4 text-slate-400">Student success, supported by platform data.</p>
          </div>
          <button onClick={signOut} className="flex w-full items-center gap-3 rounded-xl px-3 py-3 text-left text-sm font-medium text-slate-300 transition hover:bg-red-500/10 hover:text-red-200"><span>🚪</span> Sign out</button>
        </div>
      </aside>
      <main className="flex min-w-0 flex-1 flex-col overflow-hidden">
        <header className="sticky top-0 z-20 border-b border-slate-200 bg-white/95 px-4 py-3 backdrop-blur md:px-8">
          <div className="flex items-center gap-3">
            <button type="button" aria-label="Open navigation menu" onClick={() => setMobileNavOpen(true)} className="rounded-xl border border-slate-200 px-3 py-2 text-lg hover:bg-slate-50 lg:hidden">☰</button>
            <div className="min-w-0 flex-1"><p className="text-[10px] font-bold uppercase tracking-[0.2em] text-blue-600">PROK / Workspace</p><h1 className="truncate text-lg font-bold text-slate-900">{activePage.label}</h1></div>
            {searchBox()}
            <button type="button" onClick={() => window.location.reload()} className="inline-flex flex-shrink-0 items-center gap-2 rounded-xl border border-slate-200 px-3 py-2.5 text-sm font-semibold text-slate-700 transition hover:border-blue-200 hover:bg-blue-50 hover:text-blue-700" title="Reload and fetch the latest data"><span aria-hidden="true">↻</span><span className="hidden md:inline">Refresh</span></button>
          </div>
          <div className="mt-3">{searchBox(true)}</div>
        </header>
        <div className="min-h-0 flex-1 overflow-auto p-4 md:p-8"><Outlet /></div>
      </main>
    </div>
  )
}
