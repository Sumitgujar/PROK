import { useCallback, useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../services/api";
import { downloadCsv } from "../utils/exportCsv";
import { PageHeader, LoadingSpinner, ErrorMessage, EmptyState, Badge, PageShell, Card } from "../components/ui";

interface AtRiskStudent {
  student_id?: string;
  student_name?: string;
  risk_level?: string;
  overall_attendance?: number;
  reasons?: string[];
}
interface ScholarshipMatch {
  student_id?: string;
  student_name?: string;
  scholarship_name?: string;
  match_score?: number;
}
interface InsightData {
  at_risk_students?: AtRiskStudent[];
  scholarship_matches?: ScholarshipMatch[];
}

function normalizeArray<T>(value: unknown, key: string): T[] {
  if (Array.isArray(value)) return value as T[];
  if (value && typeof value === "object" && Array.isArray((value as Record<string, unknown>)[key])) {
    return (value as Record<string, unknown>)[key] as T[];
  }
  return [];
}

export function AIInsightsPage() {
  const [data, setData] = useState<InsightData | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState("");
  const [riskFilter, setRiskFilter] = useState("ALL");
  const [riskSearch, setRiskSearch] = useState("");
  const [matchSearch, setMatchSearch] = useState("");

  const load = useCallback(async (quiet = false) => {
    if (quiet) setRefreshing(true);
    else setLoading(true);
    setError("");
    try {
      const response = await api.get("/intelligence/admin/overview");
      const payload = response?.data ?? response;
      setData({
        at_risk_students: normalizeArray<AtRiskStudent>(payload?.at_risk_students, "at_risk_students"),
        scholarship_matches: normalizeArray<ScholarshipMatch>(payload?.scholarship_matches, "scholarship_matches"),
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load AI insights.");
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const atRisk = data?.at_risk_students ?? [];
  const matches = data?.scholarship_matches ?? [];
  const highRisk = atRisk.filter(student => student.risk_level === "HIGH");
  const mediumRisk = atRisk.filter(student => student.risk_level === "MEDIUM");

  const filteredRisk = useMemo(() => {
    const query = riskSearch.trim().toLowerCase();
    return atRisk
      .filter(student => riskFilter === "ALL" || student.risk_level === riskFilter)
      .filter(student => !query || [
        student.student_name ?? "",
        student.student_id ?? "",
        student.risk_level ?? "",
        ...(student.reasons ?? []),
      ].some(value => value.toLowerCase().includes(query)))
      .sort((a, b) => {
        const level = (a.risk_level === "HIGH" ? 0 : a.risk_level === "MEDIUM" ? 1 : 2)
          - (b.risk_level === "HIGH" ? 0 : b.risk_level === "MEDIUM" ? 1 : 2);
        return level || Number(a.overall_attendance ?? 100) - Number(b.overall_attendance ?? 100);
      });
  }, [atRisk, riskFilter, riskSearch]);

  const filteredMatches = useMemo(() => {
    const query = matchSearch.trim().toLowerCase();
    return matches
      .filter(match => !query || [
        match.student_name ?? "",
        match.student_id ?? "",
        match.scholarship_name ?? "",
      ].some(value => value.toLowerCase().includes(query)))
      .sort((a, b) => Number(b.match_score ?? 0) - Number(a.match_score ?? 0));
  }, [matches, matchSearch]);

  const exportRisk = () => downloadCsv("prok-at-risk-students.csv", filteredRisk.map(student => ({
    Student: student.student_name ?? "",
    "Student ID": student.student_id ?? "",
    "Risk Level": student.risk_level ?? "UNKNOWN",
    "Overall Attendance (%)": student.overall_attendance ?? "",
    Reasons: (student.reasons ?? []).join("; "),
  })));

  const exportMatches = () => downloadCsv("prok-scholarship-matches.csv", filteredMatches.map(match => ({
    Student: match.student_name ?? "",
    "Student ID": match.student_id ?? "",
    Scholarship: match.scholarship_name ?? "",
    "Match Score (%)": match.match_score ?? "",
  })));

  if (loading) return <LoadingSpinner message="Loading AI insights from the backend…" />;
  if (error && !data) return <PageShell><PageHeader title="AI Insights" sub="Explainable student-risk and scholarship matching insights." /><ErrorMessage message={error} onRetry={() => void load()} /></PageShell>;

  return (
    <PageShell>
      <div className="flex flex-wrap items-end justify-between gap-3">
        <PageHeader title="AI Insights" sub="Explore explainable risk signals and scholarship matches from PROK's rule-based intelligence service." />
        <button onClick={() => void load(true)} disabled={refreshing} className="mb-6 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50">{refreshing ? "Refreshing…" : "↻ Refresh insights"}</button>
      </div>

      {error && <div role="status" className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">Refresh failed. Showing the last loaded results: {error}</div>}
      <div className="rounded-xl border border-blue-100 bg-blue-50 px-4 py-3 text-sm leading-6 text-blue-900">
        <strong>Decision support, not an automated decision.</strong> These risk levels and match scores come from the backend's rule-based analysis of available records. Staff should review the context before acting.
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        {[
          { label: "High risk", value: highRisk.length, tone: "border-l-red-500", detail: "Prioritize human review" },
          { label: "Medium risk", value: mediumRisk.length, tone: "border-l-amber-500", detail: "Monitor and follow up" },
          { label: "Scholarship matches", value: matches.length, tone: "border-l-emerald-500", detail: "Candidate matches across students" },
        ].map(metric => <div key={metric.label} className={"rounded-2xl border border-slate-200 border-l-4 " + metric.tone + " bg-white p-4 shadow-sm"}>
          <p className="text-xs font-bold uppercase tracking-wide text-slate-500">{metric.label}</p>
          <p className="mt-2 text-3xl font-bold tabular-nums text-slate-900">{metric.value.toLocaleString()}</p>
          <p className="mt-1 text-xs text-slate-400">{metric.detail}</p>
        </div>)}
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
        <Card className="min-w-0">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div><h2 className="text-base font-bold text-slate-900">At-risk students</h2><p className="mt-1 text-sm text-slate-500">Filter by risk level or search names, IDs and recorded reasons.</p></div>
            <button onClick={exportRisk} disabled={!filteredRisk.length} className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">↓ Export CSV</button>
          </div>
          <div className="mt-4 grid grid-cols-1 gap-2 sm:grid-cols-[minmax(0,1fr)_140px]">
            <label className="text-xs font-semibold text-slate-500">Search<input type="search" value={riskSearch} onChange={event => setRiskSearch(event.target.value)} placeholder="Student, ID or reason…" className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-normal outline-none focus:border-blue-400" /></label>
            <label className="text-xs font-semibold text-slate-500">Risk level<select value={riskFilter} onChange={event => setRiskFilter(event.target.value)} className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-normal"><option value="ALL">All levels</option><option value="HIGH">High</option><option value="MEDIUM">Medium</option></select></label>
          </div>
          <div className="mt-3 text-xs text-slate-400">Showing {filteredRisk.length} of {atRisk.length} at-risk students</div>
          {filteredRisk.length === 0 ? <EmptyState title={atRisk.length ? "No students match these filters" : "No at-risk students returned"} sub={atRisk.length ? "Clear the search or choose another risk level." : "The backend returned no students in the high- or medium-risk groups."} /> :
            <div className="mt-3 divide-y divide-slate-100">
              {filteredRisk.map((student, index) => <article key={(student.student_id ?? student.student_name ?? "student") + "-" + index} className="py-3">
                <div className="flex items-start gap-3">
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2"><p className="text-sm font-semibold text-slate-900">{student.student_name || student.student_id || "Unknown student"}</p><Badge status={student.risk_level ?? "UNKNOWN"} /></div>
                    <p className="mt-1 text-xs text-slate-400">ID: {student.student_id || "Unavailable"} · Attendance: {Number(student.overall_attendance ?? 0)}%</p>
                    {student.reasons?.length ? <ul className="mt-2 space-y-1 text-xs leading-5 text-slate-600">{student.reasons.map((reason, i) => <li key={reason + "-" + i}>• {reason}</li>)}</ul> : <p className="mt-2 text-xs text-slate-400">No explanation returned by the backend.</p>}
                  </div>
                  <Link to="/interventions" className="flex-shrink-0 rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-700 hover:border-blue-200 hover:text-blue-700">Interventions →</Link>
                </div>
                <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-slate-100"><div className={"h-full rounded-full " + (Number(student.overall_attendance ?? 0) < 50 ? "bg-red-500" : "bg-amber-500")} style={{ width: Math.min(100, Math.max(0, Number(student.overall_attendance ?? 0))) + "%" }} /></div>
              </article>)}
            </div>}
        </Card>

        <Card className="min-w-0">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div><h2 className="text-base font-bold text-slate-900">Scholarship matches</h2><p className="mt-1 text-sm text-slate-500">Search the match list and sort by score.</p></div>
            <button onClick={exportMatches} disabled={!filteredMatches.length} className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-40">↓ Export CSV</button>
          </div>
          <label className="mt-4 block text-xs font-semibold text-slate-500">Search matches<input type="search" value={matchSearch} onChange={event => setMatchSearch(event.target.value)} placeholder="Student or scholarship…" className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-normal outline-none focus:border-blue-400" /></label>
          <div className="mt-3 text-xs text-slate-400">Showing {filteredMatches.length} of {matches.length} matches</div>
          {filteredMatches.length === 0 ? <EmptyState title={matches.length ? "No matching results" : "No scholarship matches returned"} sub={matches.length ? "Try a different student or scholarship name." : "The backend returned no likely matching scholarships for the available profiles."} /> :
            <div className="mt-3 divide-y divide-slate-100">
              {filteredMatches.map((match, index) => {
                const score = Math.min(100, Math.max(0, Number(match.match_score ?? 0)));
                return <article key={(match.student_id ?? match.student_name ?? "student") + "-" + (match.scholarship_name ?? "scholarship") + "-" + index} className="flex items-center gap-3 py-3">
                  <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-xl bg-emerald-50 text-base">🏆</div>
                  <div className="min-w-0 flex-1"><p className="truncate text-sm font-semibold text-slate-900">{match.scholarship_name || "Unnamed scholarship"}</p><p className="mt-1 truncate text-xs text-slate-500">{match.student_name || match.student_id || "Unknown student"}</p><div className="mt-2 h-1.5 overflow-hidden rounded-full bg-slate-100"><div className="h-full rounded-full bg-emerald-500" style={{ width: score + "%" }} /></div></div>
                  <span className="rounded-lg bg-emerald-50 px-2.5 py-1 text-sm font-bold tabular-nums text-emerald-800">{score}%</span>
                </article>;
              })}
            </div>}
          <Link to="/scholarships" className="mt-4 inline-flex rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-700 hover:border-blue-200 hover:text-blue-700">Review applications →</Link>
        </Card>
      </div>

      <p className="text-xs text-slate-400">Insights are generated from current backend records when the page loads or refreshes. They do not represent a trained-machine-learning prediction or a guarantee of scholarship eligibility.</p>
    </PageShell>
  );
}
