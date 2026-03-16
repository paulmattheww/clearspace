# ClearSpace AI: Financial & Operating Projections (36 Months)

> Last updated: March 2026. All figures in USD.

---

## Executive Summary

**Business Model:** Freemium utility. Free to scan, preview 5 swipes per category, and delete. Pro unlocks unlimited swiping + bulk actions.

**Pricing:**
| Tier | Price | ARPU Contribution | Purpose |
|------|-------|-------------------|---------|
| Weekly | $4.99/wk | ~$260/yr if retained | Impulse purchase for "Storage Full" panic |
| Annual | $29.99/yr | $29.99/yr | Primary revenue driver, marketed as "Save 80%" |
| Lifetime | $49.99 | One-time | Introduced Month 6 for long-term LTV capture |

**Core Advantage:** $0 server/API costs. 100% on-device processing via Apple native APIs (PhotoKit, Vision, CoreImage). Gross margin is functionally 85% (after Apple's cut).

**Target Audience:** 200M+ iOS users who have seen "iPhone Storage Full" at least once. Primary demographics: 18–35 with 10K+ photo libraries, heavy screenshot/social media users.

---

## 1. Key Assumptions

### Revenue Drivers
| Assumption | Base | Bull | Bear |
|------------|------|------|------|
| App Store views → install rate | 30% | 40% | 20% |
| Install → free trial start | 25% | 35% | 15% |
| Trial → paid conversion | 16% | 22% | 10% |
| **Blended view → paid** | **1.2%** | **3.1%** | **0.3%** |
| Annual plan mix (vs weekly) | 70% | 60% | 80% |
| Monthly churn (annual subs) | 5% | 3% | 8% |
| Monthly churn (weekly subs) | 30% | 20% | 40% |

### Cost Structure
| Item | Cost | Notes |
|------|------|-------|
| Server / API | $0 | 100% on-device |
| Apple Commission | 15% → 30% | 15% under Small Business Program up to $1M/yr, 30% after |
| Apple Search Ads CPA | $2.50 – $8.00 | "storage cleaner", "photo cleaner" keywords |
| Meta/TikTok CPI | $1.50 – $4.00 | Video ads showing satisfying swipe UX |
| RevenueCat | $0 → $100/mo | Free tier up to $2.5K MTR, then 0.8% |
| Developer account | $99/yr | Apple Developer Program |
| Privacy policy hosting | $0 | GitHub Pages |

---

## 2. Monthly Cash Flow: Base Case

*Steady organic growth Months 1–4, paid acquisition begins Month 5. RevenueCat integrated Month 2.*

| Month | New Subs | Active Subs | Gross Revenue | Apple Cut | Ad Spend | Other | **Net Cash Flow** | **Cumulative** |
|------:|--------:|----------:|-------------:|---------:|---------:|------:|------------------:|---------------:|
| 1 | 200 | 200 | $5,998 | -$900 | $0 | -$99 | **+$4,999** | $4,999 |
| 2 | 350 | 520 | $15,594 | -$2,339 | $0 | -$200 | **+$13,055** | $18,054 |
| 3 | 500 | 940 | $28,188 | -$4,228 | $0 | -$200 | **+$23,760** | $41,814 |
| 4 | 600 | 1,400 | $41,986 | -$6,298 | $2,000 | -$200 | **+$33,488** | $75,302 |
| 5 | 800 | 2,000 | $59,980 | -$8,997 | $5,000 | -$200 | **+$45,783** | $121,085 |
| 6 | 1,000 | 2,700 | $80,973 | -$12,146 | $8,000 | -$200 | **+$60,627** | $181,712 |
| 7 | 1,100 | 3,300 | $98,967 | -$14,845 | $10,000 | -$200 | **+$73,922** | $255,634 |
| 8 | 1,200 | 3,800 | $113,962 | -$17,094 | $12,000 | -$200 | **+$84,668** | $340,302 |
| 9 | 1,300 | 4,200 | $125,958 | -$18,894 | $12,000 | -$200 | **+$94,864** | $435,166 |
| 10 | 1,400 | 4,500 | $134,955 | -$20,243 | $12,000 | -$200 | **+$102,512** | $537,678 |
| 11 | 1,500 | 4,700 | $140,953 | -$21,143 | $12,000 | -$200 | **+$107,610** | $645,288 |
| 12 | 1,500 | 4,800 | $143,952 | -$21,593 | $12,000 | -$200 | **+$110,159** | $755,447 |
| **Year 1** | **11,450** | | **$991,466** | **-$148,720** | **-$85,000** | **-$2,299** | **+$755,447** | |
| 13 | 2,000 | 5,500 | $164,945 | -$26,391 | $18,000 | -$500 | **+$120,054** | $875,501 |
| 14 | 2,200 | 6,200 | $185,938 | -$29,750 | $20,000 | -$500 | **+$135,688** | $1,011,189 |
| 15 | 2,500 | 7,000 | $209,930 | -$44,085 | $22,000 | -$500 | **+$143,345** | $1,154,534 |
| 16 | 2,800 | 7,800 | $233,922 | -$49,123 | $25,000 | -$500 | **+$159,299** | $1,313,833 |
| 17 | 3,000 | 8,500 | $254,915 | -$53,532 | $28,000 | -$500 | **+$172,883** | $1,486,716 |
| 18 | 3,200 | 9,100 | $272,909 | -$57,311 | $30,000 | -$500 | **+$185,098** | $1,671,814 |
| 19 | 3,500 | 9,800 | $293,902 | -$61,719 | $32,000 | -$500 | **+$199,683** | $1,871,497 |
| 20 | 3,500 | 10,200 | $305,898 | -$64,239 | $32,000 | -$500 | **+$209,159** | $2,080,656 |
| 21 | 3,500 | 10,500 | $314,895 | -$66,128 | $32,000 | -$500 | **+$216,267** | $2,296,923 |
| 22 | 3,500 | 10,700 | $320,893 | -$67,388 | $32,000 | -$500 | **+$221,005** | $2,517,928 |
| 23 | 3,500 | 10,800 | $323,892 | -$68,017 | $32,000 | -$500 | **+$223,375** | $2,741,303 |
| 24 | 3,500 | 10,900 | $326,891 | -$68,647 | $32,000 | -$500 | **+$225,744** | $2,967,047 |
| **Year 2** | **36,700** | | **$3,308,930** | **-$636,130** | **-$335,000** | **-$6,000** | **+$2,211,600** | |
| 25–30 | ~4,000/mo | 12,000–14,000 | ~$390K/mo | ~30% | $35K/mo | $500/mo | **~$230K/mo** | |
| 31–36 | ~4,500/mo | 15,000–17,000 | ~$470K/mo | ~30% | $40K/mo | $500/mo | **~$280K/mo** | |
| **Year 3** | **~51,000** | | **$5,160,000** | **-$1,548,000** | **-$450,000** | **-$6,000** | **+$3,156,000** | |

### Base Case Summary

| | Year 1 | Year 2 | Year 3 | **36-Mo Total** |
|---|------:|------:|------:|------:|
| **Gross Revenue** | $991K | $3.31M | $5.16M | **$9.46M** |
| **Net Cash Flow** | $755K | $2.21M | $3.16M | **$6.13M** |
| **Cumulative** | $755K | $2.97M | $6.13M | |

**Exit Potential (Year 3):** $9M–$15M to a PE app aggregator (Bending Spoons, MWM, Gummicube) at 3–5x trailing annual cash flow.

---

## 3. Monthly Cash Flow: Bull Case

*Viral TikTok UGC drives near-zero CAC for Months 1–8. "Oddly satisfying" swipe videos generate 50M+ organic views. Lifetime plan ($49.99) introduced Month 6 and represents 15% of revenue.*

| Period | Active Subs | Gross Revenue | Apple Cut | Ad Spend | **Net Cash Flow** | **Cumulative** |
|--------|----------:|-------------:|---------:|---------:|------------------:|---------------:|
| Month 1 | 800 | $23,992 | -$3,599 | $0 | **+$20,293** | $20,293 |
| Month 2 | 2,500 | $74,975 | -$11,246 | $0 | **+$63,529** | $83,822 |
| Month 3 | 5,000 | $149,950 | -$22,493 | $0 | **+$127,257** | $211,079 |
| Month 4 | 8,000 | $239,920 | -$35,988 | $2,000 | **+$201,732** | $412,811 |
| Month 5 | 11,000 | $329,890 | -$49,484 | $5,000 | **+$275,206** | $688,017 |
| Month 6 | 15,000 | $449,850 | -$67,478 | $8,000 | **+$374,172** | $1,062,189 |
| Month 7–12 | 18K–25K | $540K–$750K/mo | 22–30% | $10–15K/mo | **~$400K/mo** | |
| **Year 1** | **25,000** | | **$5.4M** | **-$1.19M** | | **~$3.9M** |
| **Year 2** | **70,000** | | **$12.6M** | **-$3.28M** | **-$600K** | **~$12.6M** |
| **Year 3** | **140,000** | | **$22.4M** | **-$6.27M** | **-$1.2M** | **~$27.5M** |

### Bull Case Summary

| | Year 1 | Year 2 | Year 3 | **36-Mo Total** |
|---|------:|------:|------:|------:|
| **Gross Revenue** | $5.4M | $12.6M | $22.4M | **$40.4M** |
| **Net Cash Flow** | $3.9M | $8.7M | $14.9M | **$27.5M** |

**Exit Potential:** $40M–$80M (3–5x revenue multiple for a high-growth, zero-COGS subscription app). Strategic acquisition by Apple, Google Photos, or PE rollup.

**Key Bull Triggers:**
- TikTok UGC video hits 10M+ views organically
- Featured in App Store "Apps We Love" or "Clean Start" editorial
- iOS 19 WWDC keynote mentions third-party storage tools (rising tide)

---

## 4. Monthly Cash Flow: Bear Case

*Apple ships native auto-cleanup in iOS 19 (Sept 2027). Paid ads become unprofitable by Month 8. Revenue plateaus on residual ASO keyword traffic ("storage cleaner app"). No viral moment.*

| Period | Active Subs | Gross Revenue | Apple Cut | Ad Spend | **Net Cash Flow** | **Cumulative** |
|--------|----------:|-------------:|---------:|---------:|------------------:|---------------:|
| Month 1 | 100 | $2,999 | -$450 | $0 | **+$2,450** | $2,450 |
| Month 2 | 200 | $5,998 | -$900 | $0 | **+$4,999** | $7,449 |
| Month 3 | 350 | $10,497 | -$1,575 | $1,000 | **+$7,822** | $15,271 |
| Month 4 | 450 | $13,496 | -$2,024 | $2,000 | **+$9,272** | $24,543 |
| Month 5 | 550 | $16,495 | -$2,474 | $3,000 | **+$10,821** | $35,364 |
| Month 6 | 650 | $19,494 | -$2,924 | $3,000 | **+$13,370** | $48,734 |
| Month 7–12 | 700–900 | $21K–$27K/mo | 15% | $3K/mo | **~$14K/mo** | |
| **Year 1** | **900** | | **$200K** | **-$30K** | | **~$133K** |
| **Year 2** | **1,500** | | **$320K** | **-$48K** | **-$36K** | **~$369K** |
| **Year 3** | **1,200** *(declining)* | | **$260K** | **-$39K** | **-$24K** | **~$566K** |

### Bear Case Summary

| | Year 1 | Year 2 | Year 3 | **36-Mo Total** |
|---|------:|------:|------:|------:|
| **Gross Revenue** | $200K | $320K | $260K | **$780K** |
| **Net Cash Flow** | $133K | $236K | $197K | **$566K** |

**Takeaway:** Even with Apple cannibalizing the market and zero viral traction, the $0 COGS architecture means the app generates **$566K+ profit over 36 months** as a passive income stream requiring <2 hours/month of maintenance.

**Bear Mitigations:**
- Pivot to "Photo Vault" (hide + lock photos) if cleanup market dies
- License the swipe UI as a white-label SDK to other utility apps
- Sell the keyword rankings + subscriber base to a PE aggregator for 2–3x trailing FCF

---

## 5. Execution Milestones

### Phase 1: MVP Launch (Months 1–2) ✅ COMPLETE

| Milestone | Status | Details |
|-----------|--------|---------|
| Core scanning engine | ✅ Done | Screenshots, large videos, blur, duplicates |
| Swipe UI with gestures | ✅ Done | Drag, buttons, undo, tutorial overlay |
| Batched deletion | ✅ Done | Single iOS permission popup |
| Free preview (5 swipes) | ✅ Done | Paywall after preview, not at door |
| Device storage gauge | ✅ Done | Used/free/reclaimable visualization |
| Scan caching | ✅ Done | Instant cold starts, 7-day TTL |
| Trash persistence | ✅ Done | Survives app restarts |
| Cleanup streaks | ✅ Done | Consecutive-day tracking |
| Share results | ✅ Done | Viral "I freed X GB" share sheet |
| Sort options | ✅ Done | Newest/oldest/largest |
| Accessibility | ✅ Done | Full VoiceOver support |
| Privacy manifest | ✅ Done | PrivacyInfo.xcprivacy |

### Phase 2: Monetization (Months 2–3)

| Milestone | Target Date | Details |
|-----------|------------|---------|
| RevenueCat integration | Month 2 | Wire up PaywallView, restore purchases, receipt validation |
| A/B test paywall copy | Month 2 | Test "Start Free Trial" vs "Unlock Pro" vs "Save My Storage" |
| Weekly vs annual split test | Month 3 | Optimize for LTV, not just conversion rate |
| Lifetime plan ($49.99) | Month 6 | Capture high-intent users, improve LTV floor |
| Introductory offer | Month 3 | $0.99 first week, auto-renews at $29.99/yr |

### Phase 3: Growth (Months 3–6)

| Milestone | Target Date | Details |
|-----------|------------|---------|
| App Store optimization (ASO) | Month 3 | Keywords: "storage cleaner", "photo cleaner", "free up space iPhone" |
| Screenshot/preview video | Month 3 | Before/after storage gauge, satisfying swipe montage |
| TikTok UGC seeding | Month 3 | Send app to 20 "phone hacks" creators, no paid deal |
| Apple Search Ads basic | Month 4 | $50/day budget on exact-match "storage cleaner" |
| Localization (top 5 markets) | Month 5 | Spanish, Portuguese, German, French, Japanese |
| Referral program | Month 6 | "Share with a friend, both get 1 week free" |

### Phase 4: Retention & Expansion (Months 6–12)

| Milestone | Target Date | Details |
|-----------|------------|---------|
| Monthly review notifications | ✅ Done | 1st of month local time |
| Background app refresh scan | Month 6 | Lightweight scan on background wake |
| Widgets (home/lock screen) | Month 7 | "X junk items found" glanceable widget |
| iCloud shared library support | Month 8 | Scan shared albums for duplicates |
| "Smart Clean" auto-recommendations | Month 9 | "You have 300 screenshots from 2023. Trash all?" |
| Apple Watch complication | Month 10 | Storage gauge + "scan now" button |
| iPad support | Month 11 | Optimized layout for larger screens |

### Phase 5: Scale & Exit Prep (Months 12–36)

| Milestone | Target Date | Details |
|-----------|------------|---------|
| $1M ARR | Month 10–14 | Triggers exit optionality |
| Meta/Instagram paid ads | Month 12 | Video ads targeting "iPhone storage full" interest |
| Annual subscriber renewal cohort | Month 13 | First meaningful renewal revenue wave |
| Contact PE aggregators | Month 18 | Bending Spoons, MWM, Appfigures, GenITeam |
| $3M ARR | Month 18–24 | Premium exit threshold |
| Second app (Android port or adjacent tool) | Month 24 | Leverage brand + learnings |
| Exit / acquisition close | Month 30–36 | Target 3–5x trailing FCF |

---

## 6. Sensitivity Analysis

### What moves the needle most?

| Variable | +10% Change | Revenue Impact (Year 2) |
|----------|------------|------------------------|
| Conversion rate (trial → paid) | +1.6pp → 17.6% | +$330K (+10%) |
| Monthly churn (annual subs) | -0.5pp → 4.5% | +$420K (+13%) |
| Average revenue per user | +$3 → $33/yr | +$270K (+8%) |
| App Store views (organic ASO) | +10K/mo views | +$180K (+5%) |
| Weekly plan adoption | +5pp → 35% | +$500K (+15%) |

**Highest-leverage action:** Reduce churn. Monthly cleanup reminders, streaks, and the gamified UX are specifically designed for this. A 1pp churn reduction is worth more than a 10% increase in ad spend.

### Break-even timeline

| Scenario | Monthly break-even | Cumulative break-even |
|----------|-------------------:|----------------------:|
| Base | Month 1 | Month 1 |
| Bull | Month 1 | Month 1 |
| Bear | Month 1 | Month 1 |

All scenarios are profitable from Month 1 due to $0 COGS. The only question is scale, not survival.

---

## 7. Risk Register

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Apple ships native auto-cleanup in iOS 19 | Medium (30%) | Critical | Diversify into photo vault, video compression, contact cleaner |
| App Store rejects subscription model | Low (10%) | High | Ensure full compliance with HIG 3.1.1; add clear value before paywall |
| TikTok UGC never takes off | Medium (40%) | Medium | Budget $85K+ for paid Apple Search Ads; don't depend on virality |
| RevenueCat pricing changes | Low (15%) | Low | Can self-host receipt validation on CloudKit as fallback |
| Negative press ("app that charges to delete photos") | Medium (25%) | Medium | Free tier allows full deletion; Pro only gates swipe volume, not deletion itself |
| iOS API deprecation (PhotoKit changes) | Low (10%) | Medium | Vision + CoreImage are stable frameworks; PhotoKit is foundational |

---

*This model assumes a solo founder with no salary draw. If hiring, subtract $8K–$15K/month per engineer from Net Cash Flow. The $0 COGS structure means this business supports 1–2 hires at $3M+ ARR comfortably.*
