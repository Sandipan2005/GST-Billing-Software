// v1.10.81 - a welcome for new users at the top of the Dashboard (asked for by
// the maintainer): thanks them, and whoever told them about the app, says it
// is free for good, and that support of any amount is welcome but never
// needed. On the page, not a popup; shown until closed and only while the
// business has fewer than 10 invoices (from 10 the daily support card takes
// over, so the two never show together).
import { useState } from 'react';
import { Heart, Share2, X, ShieldCheck } from 'lucide-react';
import { SUPPORT_NUDGE_MIN_INVOICES } from '../utils/supporters';
import HelpButton from './HelpButton';

const KEY = 'freegstbill_welcomeCard';
const SHARE_TEXT = 'I use Free GST Billing for my GST invoices. It is free, works offline and keeps the data on your own PC: https://github.com/Sandipan2005/GST-Billing-Software';

const isClosed = () => { try { return localStorage.getItem(KEY) === 'closed'; } catch { return false; } };

export default function WelcomeCard({ invoiceCount, onOpenSupport }) {
  const [closed, setClosed] = useState(isClosed);
  if (closed || invoiceCount >= SUPPORT_NUDGE_MIN_INVOICES) return null;
  const close = () => {
    try { localStorage.setItem(KEY, 'closed'); } catch { /* private mode */ }
    setClosed(true);
  };
  return (
    <section className="welcome-card" aria-labelledby="welcome-card-title">
      <button type="button" className="welcome-card-close" onClick={close} aria-label="Close the welcome note">
        <X size={18} />
      </button>
      <div className="welcome-card-heading">
        <div className="welcome-card-mark"><ShieldCheck size={18} /></div>
        <div>
          <h2 id="welcome-card-title">Your billing workspace is ready <HelpButton title="The welcome note" doc="dashboard#welcome-card" size={16} /></h2>
          <p className="welcome-card-kicker">Private, offline-first invoicing for your business</p>
        </div>
      </div>
      <p className="welcome-card-lead">
        Complete the essentials below once, then create invoices with your
        business details, GST settings and payment information already in place.
      </p>
      <ul className="welcome-card-points">
        <li><strong>Local by default.</strong> Your records stay on this computer and remain available offline.</li>
        <li><strong>Built for GST work.</strong> Invoices, tax totals, payments and reports stay in one place.</li>
      </ul>
      <div className="welcome-card-actions">
        <button type="button" className="welcome-card-btn welcome-card-btn-primary" onClick={onOpenSupport}>
          <Heart size={16} /> Support the project
        </button>
        <a className="welcome-card-btn" href={`https://wa.me/?text=${encodeURIComponent(SHARE_TEXT)}`} target="_blank" rel="noopener noreferrer">
          <Share2 size={16} /> Share on WhatsApp
        </a>
        <button type="button" className="welcome-card-btn welcome-card-btn-quiet" onClick={close}>Start billing</button>
      </div>
    </section>
  );
}
