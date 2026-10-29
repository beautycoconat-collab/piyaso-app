# Kıyı Supabase connection

Project: oswpkwwbjwyktuqcakhr. Existing lab schema is unrelated and untouched.
Migration `kiyi_accounts_and_catalog` was applied through the Supabase migration API.
`kiyi.sql` is the exact bootstrap schema, not an idempotent migration runner.

Implemented:
- Email/password registration and sign-in, short-lived token refresh, session scoped to the browser tab.
- Account profile and private favorites/following/blocked preferences persist to Supabase.
- Only opted-in profiles appear in plate search. Unique lowercase usernames.
- Five approved pack prices and unchanged gift prices in the database.
- Wallet balances are readable only by their owners and cannot be changed by the client.
- Demo data remains separate. Real accounts cannot use demo credit mint/spend buttons.

Verification:
- Real REST catalog request and auth settings: HTTP 200; email enabled, signup enabled.
- SQL ownership, private profile/preference isolation and wallet write denial: passed in a rolled-back transaction.
- Client hydration and financial-field exclusion tests: node --test tests/supabase-account.test.mjs
- Existing D1 status/profile-visit tests remain passing.

Still required before a full production launch:
- Configure/verify SMTP and the Auth Site URL/allowed redirects for the deployed Kıyı URL in the Supabase dashboard. This integration does not change shared project Auth settings.
- A real email confirmation + two-device sign-in smoke test with the owner's account. No user credentials were requested or test emails sent.
- A payment provider and verified server webhook before credit purchases or account spending are enabled. Never grant credits from browser callbacks.
- Existing status posts, media and visitor records still use D1/R2 and ChatGPT sign-in; no data migration has been claimed or performed.
- Live position sharing, moderation, account deletion and authenticated social graph need their own production workflows. Stored following preferences do not grant private status access.
- Profile images currently persist with profile JSON; move media to owner-scoped Storage before scaling.


## Unified domain (2026-10-23)

`kiyi-domain.sql` is the consolidated schema after migrations kiyi_unified_domain, kiyi_domain_validation, kiyi_profile_query_scope, kiyi_directory_record_scope. Do not rerun it on an existing database. `kiyi-antalya-regions.sql` is the idempotent Antalya geometry seed; İzmir is intentionally unavailable.

Authenticated clients use `public.kiyi_command`; direct domain table grants are revoked. The private security-definer dispatcher verifies auth identity and ownership, blocks, balance, product prices and media ownership. Wallet deduction, inventory/gift creation, ledger and gift notification commit atomically. Storage objects use the private kiyi-media bucket and short-lived signed reads. Client credentials are publishable only.

Tests: `node --test tests/*.test.cjs tests/*.test.mjs`; execute `tests/domain-integration.sql` and `tests/domain-location.sql` as single transactions (fixtures roll back). Legacy status handler tests still describe the retained old implementation; the public legacy route now returns 410. Old D1/R2 content has NOT been migrated or deleted. A verified identity mapping is required before any legacy import.

Initial transport polls account changes every 15 seconds while visible; GPS updates are throttled to 5 seconds and only the latest point is stored per account. Map reads require a point received within 90 seconds. This is not a benchmark or production-scale realtime guarantee. Browser backgrounding stops sharing. Native iOS background location is not implemented.

Not live: payment-provider receipt/webhook verification, credit top-ups, Premium purchase activation, APNs/FCM delivery, admin review UI, account deletion workflow, legacy import, load testing and retention automation. Orders/devices tables reserve the models; their presence does not mean these integrations are enabled. No client can mint credits or approve verification. Auth/email settings belong to a shared Supabase project and were not changed.
