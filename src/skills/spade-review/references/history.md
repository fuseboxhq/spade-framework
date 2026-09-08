# Review History

Read this reference only when explaining review-contract evolution or compatibility.
### History

The review ran as a **fixed** panel from v1.1 through v1.12: five
personas through v1.1–v1.x; M-994 folded the `yagni-simplicity` persona's
remit into the scope guardian (gold-plating, proportionality) and the
adversarial reviewer (second-order, compounding cost), down to four;
M-1248 added the `alternatives-analyst` (back to five); M-1293 gave the
analyst a Scope-mode remit and put it on every roster (a uniform five).
v1.13.0 replaced the fixed panel with **dynamic casting under
drop-with-cause**: the five canonical personas became defaults a triage
step draws from, plus ad-hoc personas for dimensions no canonical lane
covers. PS-1692 then replaced drop-with-cause (which, by defaulting to
keeping, still cast almost the whole library every review) with
**cast-on-evidence**: each seat is earned by a named signal, the cast is
bounded by a floor of three and a signal-ranked soft cap of five, and
`dropped[]` records only the notable exclusions. PS-1692 also grew the
library from five to **eight**, adding three domain lenses (`operability`,
`migration-reversibility`, `delivery-semantics`); the bounded,
evidence-driven selector carries the larger library without enlarging a
typical cast (see `docs/FRAMEWORK.md` §"Stance vs domain personas"). The
existing personas and their briefs are unchanged — only how the roster is
selected and recorded became evidence-driven. See `docs/FRAMEWORK.md`
§Multi-persona Review for the rationale.
