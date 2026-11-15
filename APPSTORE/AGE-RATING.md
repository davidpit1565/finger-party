# Age rating questionnaire answers

Status: draft. I checked Apple's "Age ratings values and definitions" page on 2026-11-04. It lists the current items below and the tiers 4+, 9+, 13+, 16+, 18+. The exact question wording and answer labels in App Store Connect (e.g. None / Infrequent / Frequent, or Yes/No for capabilities) may differ or change, so **the owner must confirm each answer in the live questionnaire**. Answers are about this app's actual MVP content.

| Category | Item | Answer | Reason |
|---|---|---|---|
| In-App Controls | Parental Controls | No | None in app |
| In-App Controls | Age Assurance | No | None in app |
| Capabilities | Unrestricted Web Access | No | No web view or browser. (The Privacy Policy link, if it opens in the system browser, is a single fixed link, not unrestricted access.) |
| Capabilities | User-Generated Content | No | Users create no content that is shared or stored |
| Capabilities | Social Media | No | |
| Capabilities | Social Media Disabled for Users Under 13 | No / n/a | |
| Capabilities | Messaging and Chat | No | |
| Capabilities | Advertising | No | No ads |
| Mature Themes | Profanity or Crude Humor | None | |
| Mature Themes | Horror/Fear Themes | None | |
| Mature Themes | Alcohol, Tobacco, or Drug Use or References | None | |
| Medical or Wellness | Medical or Treatment Information | None | |
| Medical or Wellness | Health or Wellness Topics | None | |
| Sexuality or Nudity | Mature or Suggestive Themes | None | |
| Sexuality or Nudity | Sexual Content or Nudity | None | |
| Sexuality or Nudity | Graphic Sexual Content and Nudity | None | |
| Violence | Cartoon or Fantasy Violence | None | |
| Violence | Realistic Violence | None | |
| Violence | Prolonged Graphic or Sadistic Realistic Violence | None | |
| Violence | Guns or Other Weapons | None | |
| Chance-Based Activities | Gambling | No | No wagering, no real or virtual stakes |
| Chance-Based Activities | Simulated Gambling | None | No casino-style play |
| Chance-Based Activities | Contests | None | No prizes or competitions. The random pick only chooses a person for informal tie-breaks |
| Chance-Based Activities | Loot Boxes | No | No purchases at all |

## Expected result
**4+** (no restricted content, no capabilities that raise the rating). Apple computes the final rating from the answers; also check the regional ratings it displays (Australia, Brazil, Korea) for surprises, though none of the rating triggers apply.

## Related choices
- Category: Entertainment (primary). Do **not** choose the Kids category or "Made for Kids" (see RESEARCH/02 and PRODUCT-SPEC section 12). A 4+ rating does not imply the Kids category.
- Because the app is a random picker used in social settings, do not describe it in the metadata as gambling, betting, or drinking-game content.
