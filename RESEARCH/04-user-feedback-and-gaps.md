# Research 04 - User feedback on competing finger-chooser apps, and gaps vs. our app

Date: 5 Nov 2026. Language: English (docs 01 and 03 are in Hebrew).
Status: desk research from public App Store reviews plus thin forum evidence. This is NOT a user study. It shows what a self-selected, review-writing minority says. It does not prove demand or predict success.

## 1. Sources actually accessed (and failures)

**Worked**
- iTunes Search API (apps and ids), via curl. Eight apps were chosen (table below).
- iTunes RSS customer-reviews JSON (`/{us,gb}/rss/customerreviews/page=1..5/id=<id>/sortby=mostrecent/json`), via curl. 1,022 reviews were pulled and de-duplicated: 579 rated 1-2 stars, 52 rated 3, 391 rated 4-5.
- HN Algolia API: found 4 relevant comments and 1 story (details in the forum notes below).
- Firecrawl web search restricted to reddit.com. It returned thread titles and snippet excerpts only (r/boardgames).

**Failed or blocked**
- reddit.com thread bodies: Firecrawl scrape ("site not supported") and Exa fetch (SOURCE_NOT_AVAILABLE) both failed. old.reddit.com search.json returned HTTP 403 "Blocked". So no Reddit comment text was read, only search-result snippets and titles.
- Google Play reviews, Product Hunt: not attempted in depth. The Play search snippet was seen only via Firecrawl search. No Play review text was collected.
- Cross-storefront coverage is only US and GB. The RSS feed returns at most about 50 recent reviews per page set per storefront, so older history is mostly missing.

**Apps and review samples** (rating counts are 1/2/3/4/5 stars in my pulled sample, not the lifetime totals)

| App | iOS id | Store rating (count) | Sample 1/2/3/4/5 |
|---|---|---|---|
| Chooser! | 1275945156 | 4.49 (39k) | 285/24/24/44/123 |
| Chwazi - Finger Chooser | 689674978 | 4.89 (1.6k) | 78/19/13/18/118 |
| PartyFun: Finger Chooser Games | 6541360645 | 4.60 (9.5k) | 106/8/4/8/35 |
| Spin The Wheel - Finger Picker | 6503692119 | 4.36 (2.0k) | 40/2/2/1/3 |
| Finger Picker: Random Selector | 1632641308 | 3.07 (41) | 5/3/3/2/5 |
| Choozy - Finger Chooser | 1619498084 | 4.61 (719) | 3/0/5/5/15 |
| Buzz - Finger Chooser | 1519271089 | 4.46 (676) | 3/0/1/0/4 |
| Random Picker | 1435548123 | 4.79 (2.0k) | 3/0/0/2/8 |

### Honest limits on the sample
- Three apps dominate: Chooser! (n=500), Chwazi (n=246), PartyFun (n=165). The other five have 7-48 reviews each, so they carry almost no weight.
- Only the most recent reviews were fetched. Chooser!'s 285 one-star reviews are mostly 2025-26, after it added a paywall. So the count measures that paywall episode, not Chooser! overall.
- Many reviewers are children and teens (e.g. "I'm a kid, where do I get money"). Several complaints concern shock or buzz "prank" apps (Buzz, PartyFun, Spin The Wheel) that are not truly who-goes-first tools.
- Counts below are my keyword classification of review text. One review can match several themes, and misclassification is likely. Treat counts as rough ranking evidence, not precise measurements.
- The forum evidence is very thin: 5 HN items plus Reddit snippets only.

## 2. Ranked complaint themes (1-2 star reviews, n=579; counts are keyword-matched, overlapping)

| Rank | Theme | Approx. count (where) | Evidence |
|---|---|---|---|
| 1 | Paywall / subscription / pay-to-play for the core feature | ~326 (Chooser! ~240, PartyFun ~74) | Chooser! (1 star, Jun 2026): "you literally have to pay for the basic chooser feature which was FREE". Chooser! (Aug 2025): free for 2 turns, then charges. Chooser! (Nov 2025): "Why are you now charging to use the finger chooser". Also: weekly pricing described as extortion, and a reviewer claims a weekly price was shown but a yearly price charged. |
| 2 | Core function stopped working / no longer detects touches (mostly Chwazi, pre-2026 rewrite) | ~77 (Chwazi ~68) | Chwazi (1 star, Dec 2025): "Doesn't register touch on the iPhone 16 pro max anymore". Chwazi (1 star, Apr 2025): "tiniest pin dot shows up where anyone puts their fingers, but it doesn't choose one". Chwazi (2 star, Jan 2025): "does not look like it is still being developed". The most-cited cause is abandonment: an old app breaking on new devices. |
| 3 | Too many ads / ad interrupts play | ~90 (Spin The Wheel ~41, PartyFun ~25, Chooser! ~19) | Spin The Wheel (1 star, Mar 2026): "unskipable add every 5 second". Choozy (1 star, Jan 2026): "ads every time a finger is placed on the screen". Finger Picker: Random Selector (2 star, Apr 2026): ad rewards never credited. |
| 4 | Slow start, forced network or loading screen, pop-ups (post-rewrite Chwazi, Chooser!) | ~50 | Chwazi (2 star, Jul 2026): "New loading screen is so slow... never used to have a loading screen". Chwazi (2 star, Sep 2026): "pop up after every choice means you can't redo a pick quickly". Chwazi (2 star, Jul 2026): needs internet. Chooser! (1 star, Aug 2026): "stop asking me to rate mid game". |
| 5 | Misleading marketing / scammy "shock" apps / surprise charges to kids | ~43 | PartyFun: many one-star reviews, "£9.99... deducted" and "doesn't shock like the advert". Chooser!: charged a yearly price (see theme 1). Mostly specific to the prank-app subcategory, not to who-goes-first tools. |
| 6 | Touch-count limits (5 on iPhone; 6-7 in some apps; app crashes or cancels beyond the limit) | ~15 as a complaint (and ~41 requests, see 4) | Chwazi (5 star, 2023): "on my iPhone 13, it can't handle more than five fingers. The screen just stays dark". Finger Picker: Random Selector (3 star, Feb 2025): "kicks u off the app if more than 7 ppl play". Chwazi (1 star, Jun 2026): "iPhone only supporting 5 fingers is wild". Three older Chwazi reviews (2015, 2017, 2019) also say 5 fingers on iPhone. An HN comment (2020) says older devices cannot recognise more than 5. |
| 7 | Unfair / not random / "always picks me" | ~10 | Chwazi (1 star, Sep 2024): "we've tested this with a decent sample size, and the results are very, very skewed". Finger Picker: Random Selector (1 star, Jul 2024): "Only land on pink". Choozy (1 star, 2024): "only chose me". Small count, but it is the trust failure that matters most for this product. An HN story, "Chwazi, but always picks the first finger", shows the fairness idea is widely understood. |
| 8 | Forced sound / ignores silent mode / pauses user's music (Chwazi 2026 update) | ~4 | Chwazi (1 star, Jun 2026): "sounds that play through silent mode. Please add a toggle". Chwazi (1 star, Jul 2026): "my music pauses... forces me to listen to the app sounds". Chwazi (4 star, Jul 2026): "pauses your music, and doesn't turn it back on". Few reviews, but these are all from regular users who previously gave 5 stars. |
| 9 | Not full-screen / old layout on modern iPhones; dots too small to see | ~9 | Chwazi (1 star, 2021): "Not full screen". Chwazi (1 star, Jul 2025): "Dots are small. Can't see them in my screen". |
| 10 | Vibration/sound setting not working; weak haptic | 2-3 | Choozy (3 star, Jun 2025): "Whenever I put on the vibration and sound setting, it never works." Buzz (1 star, Feb 2025): "U can hardly feel it." |

**Themes in your brief with little or no evidence in this sample**
- Accidental restarts and colour clashes: 4-ish loose keyword hits at most, nothing convincing.
- Landscape and rotation: 0 mentions.
- Haptics cannot be disabled: 0 specific mentions (the only haptics reviews are about haptics not working or being weak).
- Accessibility / VoiceOver / colour-blindness: 1 loose hit. Not a signal in this review pool. It is still a valid quality bar, just not something these users voice.
- Animation too slow: only 7 negative keyword hits and no specific "wait too long to see the winner" complaint. The delay complaints are all about app loading, not the pick.

## 3. Ranked "loved" themes (4-5 star, n=391; overlapping)

| Rank | Theme | Approx. count | Evidence |
|---|---|---|---|
| 1 | Settles "who goes first / who pays / who picks" without arguments, with friends, family, siblings, sleepovers | ~115 fun/social; ~43 board games / first player; ~24 settles arguments | Chwazi (5 star, 2024): "No pop ups, ads, banners... no in app purchases. All apps should strive to be this useful." Chooser! (5 star, 2024): "Great... nobody was unhappy about any decisions as it was chosen by random chance." |
| 2 | Simplicity: does exactly one thing, instantly | ~54 | Chwazi (5 star, Jul 2026): "No micro transactions. No fluff. Just a dead-simple app that does everything you need it to and nothing it doesn't." |
| 3 | Free and no ads or purchases (when true) | ~11 explicit mentions, plus the dominant 1-star paywall theme as the mirror image | Chwazi (5 star, Jan 2025): "Brilliant that it's free." Random Picker (5 star, 2021): "No glitches. No adds." |
| 4 | Team splitting | ~22 | Chwazi (5 star, 2026): "decide groups for something". |
| 5 | Long-term reliability and trust (used for years) | ~15 | Chwazi (5 star, 2023): "I've had this app for 10 years now and it continues to be the best app on my phone". |
| 6 | Themes / backgrounds / colours | ~21 (mostly Chooser! teen users) | Chooser! (5 star, 2024): "you can also change app icon and colours, and the background". |
| 7 | Truth-or-dare / dares use | ~13 (Chooser! teen users) | Chooser! (4 star, 2025): "Good game for dares". |

A strong implicit "love": people repeatedly praise the app for not changing. The 2026 Chwazi 5-star reviews that complain about the update (new loading screen, pause-music, pop-ups) show how quickly loyalty turns when a minimal tool gets heavier.

### Forum notes (thin, snippet-level)
- HN (2020, 2023): Chwazi cited as "a fun use of multi touch" for picking board-game starting players. Another comment mentions "older devices can't recognize more than 5 fingers" (22962719). A third discusses 10-touch hardware tests (36147780).
- Reddit r/boardgames, from search snippets only: repeated recommendations of Chwazi as "the best way to determine first player", threads titled "Chwazi is back, and I owe you all an open letter" and "Chwazi is back". One snippet says a competing first-player picker in BG Stats exists but "is boring. You tap a button". This hints that the tactile, fun reveal is part of the value. Thread bodies were not read; do not quote beyond that.

## 4. Feature requests seen (counts are keyword-based and include some repeats)

| Request | Approx. count | Notes |
|---|---|---|
| More than 5 fingers at once | ~41 mentions | Most frequent request by far. Mostly from Chooser! and Chwazi users. iPhone hardware or OS behaviour is likely the real limit (see section 5). |
| A one-time purchase instead of subscription/ads, or "pay once to remove ads" | ~14 | Includes Finger Picker: Random Selector (3 star): "Wish I could just purchase it instead of waiting for the ads". |
| Background / themes / colours | ~14 | Mostly Chooser! teen users. |
| Questions, dares, tasks | ~12 | Chooser! users. Competes with Touchwars / Chooser Play Store apps already in docs 01 and 03. |
| Sound toggle / respect silent mode / do not pause music | ~5 | Almost entirely 2026 Chwazi complaints. |
| Choose an order or sequence (1st, 2nd, 3rd...) instead of one winner | ~3 | One 2016 Chwazi review (4 star) asks for exactly this. |
| Online / remote play | 1 | Negligible. |
| Save a list of names (Random Picker) | 1 | Negligible, and not a finger-picker use case. |

## 5. Does our app already handle each theme? (code check of `App/Sources`, `Packages/FingerPickerCore`, `PRODUCT/PRODUCT-SPEC.md`)

| Theme | Our app | Basis |
|---|---|---|
| Paywall / subscription / pay-to-play | Yes (by design) | No StoreKit import, no purchase code anywhere; spec forbids it. |
| Too many ads | Yes (by design) | No ad SDKs in the codebase. |
| Stopped working on new iPhones / abandoned | Partially | Cannot be proven from code. It needs continuous device testing and an annual OS-update check. |
| Slow start / needs internet / pop-ups / rate prompts | Yes | No network code (no `URLSession`), no rating prompts, opens straight to the play surface. Settings is a small sheet. |
| Touch limit / crash beyond limit | Partially | `isMultipleTouchEnabled = true`; there is no cap in `FingerPickerCore` (only a minimum of 2). `touchesCancelled` is handled. But there is no evidence in tests of what happens on iPhone at 5+ simultaneous touches (iOS may cancel some of them). Needs a physical-device test; spec section 6 already asks for it. Do not state a maximum in marketing until tested. |
| Unfair / not random | Mostly yes | The winner is chosen uniformly from the frozen set before the animation (spec; injectable randomness in tests). Not visible to users, so trust is a communication gap, not an engine gap. |
| Forced sound / silent mode / pauses music | Yes | `SoundService` uses the `.ambient` category with no options, so it respects the silent switch and mixes with the user's music. Sound defaults to off. |
| Haptics | Yes | Separate Sound and Haptics toggles, persisted. |
| Accidental restart | Yes | Replay requires all old fingers to lift first; a held finger cannot join the next round (`PlayScreen` "Lift your fingers, then tap Play Again"). |
| Colour clashes / visibility | Mostly yes, one gap | Controlled 10-colour palette; dark base; touch markers are rings, not tiny dots. Gap: palette is not formally verified for colour-vision deficiency, and the "winner colour fills the screen" idea depends on the palette (see spec section 7). |
| Not full-screen / old layout | Yes | New SwiftUI app; supports portrait and both landscapes. |
| Rotation | Yes | A resize or rotation calls `invalidate()` and cancels the round safely. |
| Accessibility | Yes (above competitors) | Reduce Motion alternative, VoiceOver labels and announcements, `.allowsDirectInteraction`. |
| Idle screen dimming/auto-lock while a group deliberates | No | No `isIdleTimerDisabled` handling found. Minor, and not in the reviews; worth a quick decision. |
| More than 5 fingers | Unknown | See touch limit row. Cannot "fix" if it is a platform limit. Honest messaging is the only lever. |
| Multiple winners / ordering / teams | No (out of scope) | Spec explicitly excludes extra modes. |
| Themes / backgrounds | No (out of scope) | Spec excludes themes and colour packs. |
| Truth-or-dare / tasks | No (out of scope) | Spec excludes. |

## 6. Recommended improvements (max 8) - single-purpose, no accounts/ads/analytics/subscriptions/extra modes

All items below are recommendations only. Items that add user-facing features are marked **[needs owner approval]**.

| # | Recommendation | Evidence strength | Effort | Risk |
|---|---|---|---|---|
| 1 | **Device-test and document real simultaneous-touch behaviour (5, 6, 7+ fingers on current iPhones; iPad if supported). Make sure nothing crashes, stalls ("screen stays dark"), or silently drops a finger without the user noticing.** If the platform caps at 5 on iPhone, show the live "N fingers detected" count (already exists) so players can see the limit. Do not claim a player maximum. | High (top request ~41; real failure reports) | S-M | Low. Result may be "cannot exceed 5 on iPhone"; that is acceptable if communicated honestly. |
| 2 | **Marketing and App Store copy that states the promise competitors broke: "Free forever. No ads. No subscription. No account. Works offline. Opens instantly."** Pair with a restrained listing that does not use "shock/prank" wording. Copy only; no code. | High (the paywall/ads themes dominate negative reviews) | S | Low. Make sure the copy is permanently true; do not promise "no ads ever" unless the owner commits. **[needs owner approval for wording]** |
| 3 | **Keep it fast and light: no loading screen, no network calls, no pop-ups, no rate-prompt, no "what's new" interstitial. Treat "cold start to usable" as a regression-tested budget (e.g. under 1 second on the oldest supported device).** | High (2026 Chwazi update backlash shows how much users value this) | S | Low |
| 4 | **Add a one-line, plain-language "How it's fair" note in Settings** (e.g. "The winner is chosen at random after fingers are locked. The animation only reveals it."). | Medium (fairness complaints are few, but trust is the product) | S | Low. Must match the real engine behaviour exactly. **[needs owner approval - new user-facing text]** |
| 5 | **Verify the 10-colour palette for colour-vision deficiency (simulate protanopia/deuteranopia/tritanopia) and adjacent-hue distinctness, then adjust values if needed. Keep ring shape/halo as a non-colour cue.** | Medium (internal quality bar; also needed because the whole reveal is colour-driven) | S-M | Low. May change brand colours; needs design sign-off. **[needs owner approval if colours change]** |
| 6 | **Keep Sound off by default, honour silent switch and never interrupt the user's music; add a regression test or UI-test check for `.ambient` session behaviour.** | Medium (forced sound/music pausing was a vivid 2026 complaint) | S | Low |
| 7 | **Release-health discipline: test on each new iPhone and iOS beta before launch, keep the minimum iOS target honest, and ship at least annual maintenance updates.** The #2 complaint theme ("stopped working") is really about abandonment. | High (68 Chwazi one-star reviews) | M (ongoing) | Low |
| 8 | **Decide whether to keep the screen awake during a round (idle timer) and document the choice.** The group may take time to place fingers; auto-lock mid-round would look like a bug. | Low (no review evidence; product-logic risk only) | S | Low. Slight battery impact if left on only while the play screen is visible. **[needs owner approval]** |

**Deliberately not recommended (out of scope or poor evidence):** more game modes, truth-or-dare packs, themes or backgrounds, online play, name lists, multiple winners/turn-order output, subscriptions, ad-funded reward credits, analytics. Chooser!, Touchwars and PartyFun cover those with paywalls and ads, and their reviews show how badly that lands. If the owner later wants "pick a turn order" or "split teams" (requested by ~3 and ~22 reviewers respectively, mostly positive mentions of existing features), that is a separate decision that reopens the single-purpose scope; evidence here is too thin to justify it now.

## 7. Bottom line
- The strongest, most consistent signal across about 1,000 reviews is not a missing feature. It is trust: users who love this category love apps that are free, instant, silent unless asked, and just work. They punish paywalls, ads, rewrites that make the app slower, and apps that quietly rot on new iPhones.
- Our current implementation already avoids ads, purchases, network calls, rate prompts and forced sound, and has better accessibility than the competitors reviewed.
- The largest unknown is the real simultaneous-touch ceiling on iPhone. It drives the most common feature request and needs a physical-device test before any claim is made.
- Sample size: three apps carry almost all the data, reviews skew young and extreme, and forum evidence is minimal. Do not use these counts as market-size or demand evidence.
