"use client";

import { FormEvent, useState } from "react";
import { trackMarketingEvent } from "@/lib/marketing";

type WaitlistState = "idle" | "submitting" | "research" | "done" | "error";

const SOFTWARE = ["Serato", "rekordbox", "Traktor", "VirtualDJ", "djay Pro", "Other"];

export function WaitlistForm() {
  const [email, setEmail] = useState("");
  const [software, setSoftware] = useState<string[]>([]);
  const [state, setState] = useState<WaitlistState>("idle");
  const [message, setMessage] = useState<string | null>(null);
  const [profile, setProfile] = useState({
    djType: "",
    macosVersion: "",
    recordingFrequency: "",
    currentWorkflow: "",
    biggestPain: "",
    willingToTest: true,
  });

  function toggleSoftware(item: string) {
    setSoftware((current) =>
      current.includes(item) ? current.filter((value) => value !== item) : [...current, item],
    );
  }

  async function join(event: FormEvent) {
    event.preventDefault();
    if (software.length === 0) {
      setState("error");
      setMessage("Choose at least one DJ app.");
      return;
    }
    setState("submitting");
    setMessage(null);
    trackMarketingEvent("waitlist_started", { djSoftware: software.join(",") });
    try {
      await submit({ email, djSoftware: software, source: "landing-page" });
      trackMarketingEvent("waitlist_joined", { djSoftware: software.join(",") });
      setState("research");
    } catch (error) {
      setState("error");
      setMessage(error instanceof Error ? error.message : "Could not join the waitlist.");
    }
  }

  async function completeResearch(event: FormEvent) {
    event.preventDefault();
    setState("submitting");
    try {
      await submit({
        email,
        djSoftware: software,
        ...profile,
        researchComplete: true,
        source: "landing-page",
      });
      trackMarketingEvent("research_completed", {
        djSoftware: software.join(","),
        djType: profile.djType,
        recordingFrequency: profile.recordingFrequency,
      });
      setState("done");
      setMessage("You’re on the list. We’ll email you when your beta cohort opens.");
    } catch (error) {
      setState("error");
      setMessage(error instanceof Error ? error.message : "Could not save your beta profile.");
    }
  }

  if (state === "research" || (state === "submitting" && profile.djType)) {
    return (
      <form onSubmit={completeResearch} className="research-form">
        <div className="form-confirmation">
          <span className="status-dot" aria-hidden="true" />
          You’re on the waitlist. Help us place you in the right test cohort.
        </div>
        <div className="form-grid">
          <label>
            What kind of DJ work do you do?
            <select required value={profile.djType} onChange={(e) => setProfile({ ...profile, djType: e.target.value })}>
              <option value="">Choose one</option>
              <option>Club / nightlife</option>
              <option>Mobile / events</option>
              <option>Radio / streaming</option>
              <option>Touring artist</option>
              <option>Hobbyist / developing</option>
              <option>Other</option>
            </select>
          </label>
          <label>
            How often do you record sets?
            <select required value={profile.recordingFrequency} onChange={(e) => setProfile({ ...profile, recordingFrequency: e.target.value })}>
              <option value="">Choose one</option>
              <option>Multiple times a week</option>
              <option>About weekly</option>
              <option>About monthly</option>
              <option>A few times a year</option>
              <option>Rarely or never</option>
            </select>
          </label>
          <label>
            macOS version <span>(optional)</span>
            <input value={profile.macosVersion} onChange={(e) => setProfile({ ...profile, macosVersion: e.target.value })} placeholder="e.g. Sequoia 15" />
          </label>
          <label>
            What happens to a recording after your set? <span>(optional)</span>
            <textarea value={profile.currentWorkflow} onChange={(e) => setProfile({ ...profile, currentWorkflow: e.target.value })} rows={3} placeholder="Where it lands, how you name it, whether it gets backed up…" />
          </label>
          <label>
            What is the biggest pain in that workflow? <span>(optional)</span>
            <textarea value={profile.biggestPain} onChange={(e) => setProfile({ ...profile, biggestPain: e.target.value })} rows={3} />
          </label>
        </div>
        <button className="button button-primary" disabled={state === "submitting"} type="submit">
          {state === "submitting" ? "Saving…" : "Complete beta profile"}
        </button>
      </form>
    );
  }

  if (state === "done") {
    return <p className="form-confirmation" role="status"><span className="status-dot" aria-hidden="true" />{message}</p>;
  }

  return (
    <form onSubmit={join} className="waitlist-form">
      <label htmlFor="waitlist-email">Email</label>
      <div className="email-row">
        <input id="waitlist-email" type="email" required autoComplete="email" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} disabled={state === "submitting"} />
        <button className="button button-primary" type="submit" disabled={state === "submitting"}>
          {state === "submitting" ? "Joining…" : "Join the private beta"}
        </button>
      </div>
      <fieldset>
        <legend>Which DJ apps do you use?</legend>
        <div className="software-options">
          {SOFTWARE.map((item) => (
            <label key={item} className={software.includes(item) ? "selected" : ""}>
              <input type="checkbox" checked={software.includes(item)} onChange={() => toggleSoftware(item)} />
              {item}
            </label>
          ))}
        </div>
      </fieldset>
      {message && <p className="form-error" role="alert">{message}</p>}
      <p className="form-note">Free during beta. No card. Your audio stays on your Mac by default.</p>
    </form>
  );
}

async function submit(payload: Record<string, unknown>) {
  const response = await fetch("/api/waitlist", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  const json = (await response.json()) as { error?: string };
  if (!response.ok) throw new Error(json.error || "Could not join the waitlist.");
}
