# SPADE frontier blind result (PS-2320)

Tested head: `124698f8f1cd59caf8e65020a1af0b2c14b52482`
Input digest: `3f7d395cab2f492e0a8c8fb7447dd454cd25f3a22cbd48b312ee371020626a74`
Re-pinned for PS-3031: the map contract gained a sentence saying frontier never reaches the Evaluate record a Done rests on. No frontier case outcome changed.
Context mode: fresh isolated native `fork_turns=none` decider for each case, with canonical contracts only and explicit no-edit instructions
Cases: A1=match A2=match A3=match A4=match B1=match B2=match B3=match B4=match B5=match C1=match C2=match C3=match C4=match C5=match C6=match C7=match D1=match D2=match D3=match D4=match E1=match E2=match E3=match E4=match
Discriminating pairs: PASS
Ownership boundary: PASS
Prototype and prerequisite boundary: PASS
Canonical authority: PASS
Run-state boundary: PASS
PASS: all 24 cases match

All 24 cases matched on the first fresh decision.
The revised out-of-scope joins, named-question failure, and fail-closed digest wording preserved every existing branch and ownership boundary.
