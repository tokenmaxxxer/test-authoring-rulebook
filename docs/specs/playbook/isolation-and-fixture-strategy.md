# Operational playbook — isolation & fixture strategy

Condition → choice → source rules for this role's decides: 테스트 코드 자체가
격리성·fixture 전략 면에서 좋은 설계인가. Numbered, one rule per line item.
REMOVAL-category rules are marked `[REMOVAL]`.

## A. Fixture construction

1. Fixture setup logic duplicated across >=3 test methods in a suite →
   extract a Creation Method (parameterized factory function), not
   In-line Setup copy-paste. Source: Meszaros, *xUnit Test Patterns*,
   ch.20 Fixture Setup Patterns (http://xunitpatterns.com/Fixture%20Setup%20Patterns.html).
2. SUT construction needs >=4 collaborators and most tests only care
   about 1-2 of them → use a Creation Method with sensible defaults for
   the rest, not repeated full-argument In-line Setup. Source: same,
   ch.20.
3. Fixture is expensive to build (network call, heavy compute) and
   read-only across the whole suite → Suite Fixture Setup (build once
   per suite), never per-test rebuild. Source: xunitpatterns.com,
   Fixture Setup Patterns.
4. Fixture is cheap to build and any test in the suite might mutate it
   → Fresh Fixture per test, not Suite/Shared Fixture — Meszaros: "in
   most circumstances a transient fresh fixture is the best strategy
   because it does not have to deal with the challenges ... of fixture
   teardown." Source: John Sanda, "Test Fixture Strategies" summarizing
   Meszaros ch.20/21 (http://johnsanda.blogspot.com/2008/03/in-his-book-xunit-test-patterns-gerard.html).
5. [REMOVAL] Fixture setup is hidden inside a base TestCase class's
   `setUp`/constructor with no per-test visibility of what's built
   (Implicit Setup) and different tests in the class need materially
   different preconditions → remove Implicit Setup, replace with
   Delegated Setup / Creation Method calls made explicit in each test
   body. Source: Meszaros ch.20, Implicit Setup pattern discussion
   (http://xunitpatterns.com/Fixture%20Setup%20Patterns.html).
6. Persistent Fresh Fixture is unavoidable (DB-backed test) → pair it
   with Automated Teardown registered at setup time, not manual
   In-line Teardown at the end of each test body, since manual teardown
   is skipped whenever the test fails before reaching it. Source:
   xunitpatterns.com, Automated Teardown
   (http://xunitpatterns.com/Automated%20Teardown.html).

## B. pytest / xUnit fixture scope selection

7. Fixture setup is fast (<10ms) and any test might mutate returned
   state → function scope (pytest default). Source: pytest docs, "How
   to use fixtures" (https://docs.pytest.org/en/stable/how-to/fixtures.html).
8. Fixture setup is expensive (spins a process, loads a large file) AND
   every consumer only reads it, never mutates it → session or module
   scope, sized to the widest group of tests that share the read-only
   precondition — module scope when only one file's tests share it,
   session scope when the whole run does. Source: pytest-with-eric,
   "What Are Pytest Fixture Scopes?" (https://pytest-with-eric.com/fixtures/pytest-fixture-scope/).
9. [REMOVAL] A session/module-scoped fixture's returned object is
   mutated by any consuming test → drop the wide scope back to function
   scope, or split into a session-scoped read-only base plus a
   function-scoped copy/wrapper each test mutates — a wide-scope
   fixture whose object is mutated is exactly the "changes made by one
   test could impact subsequent tests" failure mode. Source: PythonTest,
   "pytest session scoped fixtures" (https://pythontest.com/framework/pytest/pytest-session-scoped-fixtures/).
10. A fixture is reused with genuinely different scopes needed by
    different test groups (e.g. one fast unit group wants function
    scope, one slow integration group wants session scope) → define two
    separately named fixtures (or an indirect-parametrize split), never
    force one fixture to serve both via a shared wide scope. Source:
    pawamoy, "Same Pytest fixtures with different scopes"
    (https://pawamoy.github.io/posts/same-pytest-fixtures-with-different-scopes/).

## C. Test isolation / independence

11. Any test's pass/fail outcome changes depending on which other tests
    ran before it (run in isolation vs. full suite order) → the suite
    has an order dependency; identify the polluter (test that leaves
    shared state) and the victim (test that assumes it), then remove
    the pollution instead of pinning run order. Source: arXiv 2510.26171,
    "Reduction of Test Re-runs by Prioritizing Potential Order Dependent
    Flaky Tests" (https://arxiv.org/pdf/2510.26171).
12. [REMOVAL] A test only passes when a specific earlier test (a "state
    setter") has already run and populated shared state → this is a
    brittle in the polluter/victim/state-setter taxonomy; remove the
    implicit cross-test dependency by giving the brittle its own Fresh
    Fixture rather than relying on suite order. Source: same, arXiv
    2510.26171.
13. Tests share a global variable, singleton, shared filesystem path, or
    unscoped module-level cache → isolated tests do not depend on other
    tests or share mutable state between runs; convert the shared state
    into a per-test Fresh Fixture or reset/re-instantiate it in setup.
    Source: OneUptime, "How to Fix 'Test Isolation' Issues"
    (https://oneuptime.com/blog/post/2026-01-24-fix-test-isolation-issues/view).
14. Suite is or will be run with parallel workers and multiple tests
    read/write the same database rows or files → database-related
    failures are the most common category of parallel-test flakiness
    when workers share a database; give each test/worker its own
    schema/transaction/tmp directory rather than a shared store. Source:
    same, OneUptime.

## D. Database-backed fixture strategy

15. Test touches a relational DB and does not need the data to outlive
    the test (no async job, no separate HTTP round trip processing the
    write) → wrap the test in a transaction opened at setup and rolled
    back at teardown (Automated Teardown via the DB transaction
    mechanism), not manual row deletion. Source: Los Techies (Jimmy
    Bogard), "Strategies for isolating the database in tests"
    (https://lostechies.com/jimmybogard/2013/06/18/strategies-for-isolating-the-database-in-tests/).
16. [REMOVAL] `@Transactional`-style rollback is applied to a test that
    exercises the SUT through a separate HTTP client / another thread
    or process (e.g. WebTestClient hitting a running server) → remove
    the transaction-rollback assumption; the app commits in its own
    transaction context before the test's rollback runs, so rely on
    explicit cleanup (delete/truncate in teardown) instead. Source:
    rieckpil, "Spring Boot Testing Pitfall: Transaction Rollback in
    Tests" (https://rieckpil.de/spring-boot-testing-pitfall-transaction-rollback-in-tests/).
17. Test verifies an out-of-process side effect (sent email, uploaded
    file, third-party API call) → do not rely on DB transaction
    rollback for cleanup of that side effect; use a dedicated
    fake/stub for the side-effecting client plus explicit teardown for
    any artifact it produces. Source: same, rieckpil / Green Report,
    "Techniques for Effective Test Data Cleanup in CI/CD"
    (https://www.thegreenreport.blog/articles/techniques-for-effective-test-data-cleanup-in-cicd/techniques-for-effective-test-data-cleanup-in-cicd.html).

## E. Test double selection

18. SUT's dependency has no meaningful side effects and a working
    real implementation is available and fast → prefer the real
    dependency over any test double. Source: Google, *Software
    Engineering at Google*, ch.13 Test Doubles
    (https://abseil.io/resources/swe-book/html/ch13.html).
19. Real dependency is slow/flaky/hard to construct but a lightweight
    working implementation exists or is easy to write (in-memory DB,
    in-memory queue) → use a Fake, not a Mock, when the test only needs
    the dependency's *state* to end up correct. Source: same, Google
    SWE book ch.13.
20. [REMOVAL] A test asserts that a dependency method was called with
    specific arguments (behavior verification via Mock) where a Stub
    plus state/return-value assertion would suffice → replace the Mock
    with a Stub; over-specifying call patterns couples the test to
    implementation detail and increases churn on refactors. Source:
    Google SWE book ch.13, "prefer stubs over mocks, real objects over
    test doubles, and state verification over behavior verification."
21. The test's actual goal is to verify an interaction/protocol
    contract itself (e.g. "on failure, retry exactly 3 times calling
    this API") → a Mock with call-count/argument verification is the
    correct choice here, since the interaction pattern is the thing
    under test, not incidental to it. Source: same, Google SWE book
    ch.13.

## Conflicts noted

- Google SWE book (real > fake > stub > mock) vs. Meszaros' pattern
  catalog: no direct conflict — Meszaros pins fixture *construction*
  patterns, Google pins test-double *selection*; both agree on
  minimizing indirection unless the test's own purpose requires it.
  Resolution: apply both, scoped to their respective axis (fixture
  build vs. dependency substitution).
- Transaction-rollback (rule 15) vs. rule 16's exception: not a real
  conflict, a scope boundary — rollback works only when the SUT and the
  test share one transaction/connection context; rule 16 names the
  concrete condition where that assumption breaks.
