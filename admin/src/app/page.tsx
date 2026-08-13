import Link from "next/link";
import { Show, UserButton } from "@clerk/nextjs";
import { WaitlistForm } from "@/components/WaitlistForm";
import { PageAnalytics } from "@/components/PageAnalytics";

const steps = [
  ["01", "Connect", "Choose the folder where your DJ app saves completed recordings."],
  ["02", "Protect", "DJMemory watches for a finished file, then creates a protected copy."],
  ["03", "Remember", "Find the set later with its date, source, and session context attached."],
];

export default function HomePage() {
  return (
    <main>
      <PageAnalytics />
      <header className="site-header shell">
        <Link className="wordmark" href="#top" aria-label="DJMemory home">
          <span className="mark" aria-hidden="true"><i /><i /><i /></span>
          DJMemory
        </Link>
        <nav aria-label="Main navigation">
          <Link href="#how-it-works">How it works</Link>
          <Link href="#privacy">Privacy</Link>
          <Link href="#beta">Beta</Link>
        </nav>
        <Link className="header-cta" href="#beta">Join beta</Link>
      </header>

      <section id="top" className="hero shell">
        <div className="hero-copy">
          <p className="eyebrow"><span className="status-dot" /> Private Mac beta</p>
          <h1>Your set ended.<br /><em>Its story shouldn’t.</em></h1>
          <p className="hero-lede">
            DJMemory automatically protects completed DJ recordings on your Mac—and leaves every
            original exactly where it found it.
          </p>
          <div className="hero-actions">
            <Link className="button button-primary" href="#beta">Join the private beta</Link>
            <Link className="button button-secondary" href="#demo">See how protection works <span>↓</span></Link>
          </div>
          <p className="micro-proof">Local-first · Copy-only · Serato + rekordbox first</p>
        </div>
        <div className="memory-card" aria-label="Example protected recording">
          <div className="card-topline"><span>Protection receipt</span><span className="protected"><i /> Protected</span></div>
          <div className="waveform" aria-hidden="true">
            {[18, 34, 52, 28, 64, 43, 78, 55, 36, 68, 84, 47, 72, 39, 59, 29, 45, 73, 51, 31, 61, 40, 23, 48].map((height, index) => <i key={index} style={{ height }} />)}
          </div>
          <p className="set-name">Saturday Night — Public Works</p>
          <p className="set-meta">Serato DJ Pro · 01:42:18 · Aug 8, 2026</p>
          <div className="receipt-line"><span>Original recording</span><strong>Unchanged</strong></div>
          <div className="receipt-line"><span>Protected copy</span><strong>DJMemory / 2026 / August</strong></div>
          <div className="receipt-footer"><span>Completed at 2:14 am</span><span>View in archive ↗</span></div>
        </div>
      </section>

      <section className="proof-strip" aria-label="Product principles">
        <div className="shell proof-grid">
          <p><span>01</span><strong>Your audio stays yours</strong>Nothing uploads by default.</p>
          <p><span>02</span><strong>Originals stay untouched</strong>DJMemory copies. It never moves or renames.</p>
          <p><span>03</span><strong>Built around DJ workflows</strong>Clear support paths, not vague compatibility.</p>
        </div>
      </section>

      <section id="demo" className="section shell demo-section">
        <div className="section-intro">
          <p className="eyebrow">The quiet work after the set</p>
          <h2>Protection you can see.</h2>
          <p>DJMemory does one important job in the background, then gives you a clear receipt.</p>
        </div>
        <div className="demo-window">
          <div className="window-bar"><span /><span /><span /><b>DJMemory — Protection</b></div>
          <div className="demo-sidebar">
            <strong>DJMemory</strong>
            <span className="active">Protection</span><span>Library</span><span>Capture</span><span>Settings</span>
          </div>
          <div className="demo-main">
            <p className="demo-label">SYSTEM STATUS</p>
            <h3><i className="shield" /> Your recordings are protected.</h3>
            <p>DJMemory checked your recording folders 42 seconds ago.</p>
            <div className="demo-source">
              <div className="source-icon">S</div><div><strong>Serato DJ Pro</strong><span>Recording folder connected</span></div><b>Protected</b>
            </div>
            <div className="demo-source">
              <div className="source-icon rb">R</div><div><strong>rekordbox</strong><span>Recording folder connected</span></div><b>Protected</b>
            </div>
            <div className="demo-activity"><span>Latest activity</span><strong>“Saturday Night — Public Works” archived</strong><time>2:14 am</time></div>
          </div>
        </div>
      </section>

      <section id="how-it-works" className="section shell">
        <div className="section-intro compact"><p className="eyebrow">How it works</p><h2>Three steps. Then get back to the music.</h2></div>
        <div className="steps">
          {steps.map(([number, title, copy]) => <article key={number}><span>{number}</span><h3>{title}</h3><p>{copy}</p></article>)}
        </div>
      </section>

      <section id="privacy" className="section shell privacy-section">
        <div className="privacy-copy">
          <p className="eyebrow">Local by default</p>
          <h2>Your sets are creative work.<br />DJMemory treats them that way.</h2>
          <p>Local protection works without an account. Audio and full tracklists stay on your Mac unless you explicitly export or share them.</p>
          <ul><li>Source recordings are never moved, renamed, or deleted.</li><li>Diagnostics contain setup metadata—not audio or full tracklists.</li><li>You choose the archive location and connected folders.</li></ul>
        </div>
        <blockquote><span>“</span>A tool that protects the work should not take control of it.<cite>DJMemory product principle</cite></blockquote>
      </section>

      <section className="section shell compatibility-section">
        <div><p className="eyebrow">Compatibility without guesswork</p><h2>Start with the workflows we’ve tested.</h2></div>
        <div className="compatibility-list">
          <p><strong>Serato DJ Pro</strong><span>Supported first</span></p><p><strong>rekordbox</strong><span>Supported first</span></p>
          <p><strong>Traktor</strong><span>Supported</span></p><p><strong>VirtualDJ</strong><span>Partial support</span></p><p><strong>djay Pro</strong><span>Manual setup</span></p>
        </div>
      </section>

      <section id="beta" className="beta-section">
        <div className="shell beta-grid">
          <div><p className="eyebrow">Private beta</p><h2>Help make set protection dependable.</h2><p>We’re inviting a small group of Mac DJs to test DJMemory with real recording workflows before the beta opens more widely.</p><ul><li>Free during the beta</li><li>Invites sent in small cohorts</li><li>Honest limitations and direct feedback</li></ul></div>
          <div className="waitlist-card"><WaitlistForm /></div>
        </div>
      </section>

      <section className="section shell faq-section">
        <p className="eyebrow">Questions, answered plainly</p><h2>Before you connect a folder.</h2>
        <div className="faq-grid">
          <details open><summary>Does DJMemory upload my recordings?</summary><p>No. Audio stays on your Mac by default. Local protection works without an account.</p></details>
          <details><summary>Does it change the original file?</summary><p>No. DJMemory creates a protected copy and leaves the source recording untouched.</p></details>
          <details><summary>Is this a replacement for a backup drive?</summary><p>No. If the archive is on the same physical disk, you still need a separate-device backup for full protection.</p></details>
          <details><summary>Can I download the beta now?</summary><p>Not yet. We are inviting small cohorts while clean installation and notarization are completed.</p></details>
        </div>
      </section>

      <footer className="site-footer shell"><span className="wordmark"><span className="mark" aria-hidden="true"><i /><i /><i /></span>DJMemory</span><p>Every set, remembered.</p><Show when="signed-in"><div className="admin-links"><UserButton /><Link href="/admin">Admin</Link></div></Show></footer>
    </main>
  );
}
