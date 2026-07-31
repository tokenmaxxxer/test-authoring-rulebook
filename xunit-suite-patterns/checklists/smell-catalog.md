# xUnit Test Patterns smell catalog (reference checklist)

Adapted from Gerard Meszaros, *xUnit Test Patterns: Refactoring Test Code*
(Addison-Wesley, 2007) — the canonical catalog of test smells. One line per
smell: name plus a one-sentence description. Use this as a reference
checklist when writing the suite-architecture/smell-list section of the
phase-2 record; it is not itself enforced field-by-field by the gate (the
gate only checks that a real smell name, or an explicit "no smells found"
statement, is present).

1. **Fixture Setup** — test setup is so complicated or indirect that
   readers cannot easily see what state the test starts from.
2. **General Fixture** — a shared fixture built bigger than any single test
   needs, so each test pays the cost of set up it does not use.
3. **Test Code Duplication** — the same setup/exercise/verify logic is
   copy-pasted across many tests instead of extracted into shared helpers.
4. **Conditional Test Logic** — a test contains `if`/`switch`/loops that
   make its own pass/fail path hard to verify by inspection.
5. **Mystery Guest** — a test depends on external data (a file, a database
   row) not visible in the test itself, obscuring what it actually verifies.
6. **Resource Optimism** — a test assumes an external resource (network,
   file, service) is available and in a particular state without ensuring it.
7. **Test Run War** — tests that share a mutable external resource fail
   when run concurrently or in a different order because they interfere
   with each other.
8. **Slow Tests** — tests that take long enough to run that developers stop
   running them frequently, eroding the fast-feedback loop.
9. **Eager Test** — a single test tries to verify too many behaviors at
   once, making failures hard to localize.
10. **Assertion Roulette** — a test has many assertions with no
    distinguishing failure messages, so a failure does not say which
    assertion actually failed.
11. **Sensitive Equality** — a test asserts equality against an entire
    object/string dump instead of the specific fields it cares about,
    breaking on any unrelated formatting change.
12. **Indirect Testing** — a test for one object exercises its behavior
    only through another object, making failures hard to attribute.
13. **Hard-Coded Test Data** — literal values are duplicated throughout the
    suite instead of named, so their significance and reuse are unclear.
14. **Interacting Tests** — one test's outcome depends on another test
    having run first (shared state, ordering assumptions), breaking
    isolation.
15. **Obscure Test** — a test is hard to read: intent, setup, and
    expectation are not clear from the test body itself.
16. **Test Logic in Production** — production code contains branches that
    exist only to support being tested, contaminating the production path.
17. **For Testing Only Code** — production code exposes methods or
    properties whose only purpose is to be called from tests.
18. **Publicizing Frozen State / Wet Floor** — a test leaves shared or
    static state modified after it finishes, leaving a "wet floor" that
    trips up whichever test runs next.
