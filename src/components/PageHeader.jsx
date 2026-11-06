// v1.10.37 — Reusable page-header card. Reported: "I like the heading
// that you gave into this page — I want you to do in all the pages,
// that looks better". Extracted from the SettingsView v1.10.36 header
// so every page gets a consistent visual identity: restrained card +
// icon badge + title + subtitle + optional meta chip + right-side
// action slot.
//
// Props:
//   icon        emoji / string / element rendered inside the 44px badge
//   title       page title (h1)
//   subtitle    one-line description shown below the title
//   meta        optional short string rendered as a pill next to the
//               subtitle (e.g. "231 invoices", "11 sections", "FY 2025-26")
//   children    right-hand slot for action buttons, HelpButton, etc.
//   compact     v1.10.77 (#84): a slim title row, no card, icon or subtitle,
//               for screens where the table needs the room (the Dashboard).
import { Card } from './ui/card';

export default function PageHeader({ icon, title, subtitle, meta, children, compact = false }) {
  if (compact) {
    return (
      <div className="page-header page-header-compact" style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap', marginBottom: '0.9rem' }}>
        <h1 className="page-title" style={{ margin: 0, fontSize: '1.3rem' }}>{title}</h1>
        {meta && <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', fontWeight: 600 }}>{meta}</span>}
        {/* v1.10.83 - wraps on a phone; "New Invoice" ran past the right edge at 390px. */}
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: '0.5rem', flexWrap: 'wrap', justifyContent: 'flex-end', minWidth: 0 }}>{children}</div>
      </div>
    );
  }
  return (
    <Card className="page-header" style={{
      padding: '1.1rem 1.35rem',
      background: 'var(--card-bg)',
      border: '1px solid var(--border)',
      borderRadius: 8,
      marginBottom: '1.25rem',
    }}>
      {/* v1.10.83 - flex: 1 so the help / action buttons sit at the right edge;
          the row was only as wide as its text, leaving them mid-header. */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem', flex: 1, minWidth: 0 }}>
        {icon !== undefined && (
          <div className="page-header-icon" style={{
            width: 44, height: 44,
            borderRadius: 8,
            background: 'var(--brand-teal, #0f766e)',
            color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: '1.15rem',
            boxShadow: 'none',
            flexShrink: 0,
          }}>{icon}</div>
        )}
        <div style={{ flex: 1, minWidth: 0 }}>
          <h1 className="page-title" style={{ margin: 0 }}>{title}</h1>
          {(subtitle || meta) && (
            <p className="page-subtitle" style={{ margin: '0.15rem 0 0', display: 'flex', alignItems: 'center', gap: '0.55rem', flexWrap: 'wrap' }}>
              {subtitle && <span>{subtitle}</span>}
              {meta && (
                <span style={{
                  fontSize: '0.7rem',
                  padding: '0.1rem 0.5rem',
                  borderRadius: 999,
                  background: 'var(--bg-secondary)',
                  border: '1px solid var(--border)',
                  fontWeight: 600,
                  color: 'var(--text)',
                }}>{meta}</span>
              )}
            </p>
          )}
        </div>
        {children}
      </div>
    </Card>
  );
}
