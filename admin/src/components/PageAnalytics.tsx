"use client";

import { useEffect } from "react";
import { trackMarketingEvent } from "@/lib/marketing";

export function PageAnalytics() {
  useEffect(() => {
    trackMarketingEvent("page_view");
  }, []);
  return null;
}
