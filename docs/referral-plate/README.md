# Profile and reward calendar correction

- Removed badge category navigation, own-profile eyebrow and duplicate reward launcher.
- Calendar uses native horizontal scrolling and seven-day snap pages; dots and keyboard remain usable.
- Referral flow: confirmed new account -> owned plate -> referrer reward. Amount 75, monthly cap 5 unchanged. Confirmation remains an Auth requirement, not a new step in the compact card.
- Private server helper evaluates current non-deleted owned vehicles. One consumed plate hash cannot be rewarded across accounts. Existing awards, balances, prices, daily calendar and badge definitions retained.
- Existing pending invitations use the new rule; previously paid invitations never replay. No mass payout is performed by migration. Existing five-minute settlement worker and account dashboard settle eligible awards.
- Migration: 20261026211037_referral_plate_qualification.sql. Original definitions saved for non-destructive rollback. New table RLS enabled with all client grants revoked; policy-free private access intentionally denies clients.
- SQL test `tests/referral-plate.sql` executed against disposable fixtures inside one rolled-back transaction: no plate, plate with zero activity days, duplicate payment, deletion, reinsertion, cross-account plate reuse, monthly cap, table/function access and unchanged amounts passed. These are SQL fixture tests, not a two-device Auth E2E test.
- First SQL test attempt hit the existing global plate uniqueness constraint during its reuse fixture; fixture corrected to free its own test-only plate before testing retained reward history. Re-run passed.
- Physical iPhone swipe not tested in this environment. Browser QA and automated scroll handler tests are separate checks.
