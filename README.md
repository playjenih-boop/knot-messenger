# Knot — Flutter messenger starter

Knot is a cross-platform Android/iOS messenger starter using Flutter and Supabase. The visual identity is **Midnight**: deep navy and black surfaces, sky-blue secondary indicators, and violet primary actions.

## Included in this version

- Flutter app shell with Knot Midnight design tokens
- Email/password sign-up and sign-in through Supabase Auth
- Email confirmation flow (requires configured Supabase email templates and deep links)
- Phone-number attachment and SMS OTP verification after email sign-in
- Password reset request by email
- Session-aware app gate
- Initial PostgreSQL schema for profiles, conversations, members, messages, and device tokens
- Row Level Security policies

## Requirements

- Flutter stable (Dart SDK >= 3.3)
- A Supabase project
- An SMS provider configured in Supabase Auth for phone verification
- SMTP/email templates configured in Supabase Auth

## Supabase setup

1. Create a Supabase project.
2. In **Authentication → Providers**, enable Email and Phone.
3. For Email, configure confirmation emails and a production SMTP provider. Set the app's allowed redirect URLs / deep links for email confirmation and password recovery.
4. For Phone, configure an SMS provider and OTP template. Test delivery and rate limits before release.
5. Apply `supabase/migrations/0001_initial_schema.sql` in the Supabase SQL Editor or with the Supabase CLI.
6. Confirm the `messages` table is enabled for Realtime. If the migration reports that `supabase_realtime` publication already contains `messages`, remove the duplicate `alter publication` line and re-run the rest as appropriate.

## Run locally

From this directory:

```bash
flutter create . --platforms=android,ios
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY
```

Use only the public anon/publishable key in the mobile client. **Never** embed the Supabase service-role key in an app.

## Registration behavior

1. User enters display name, email, and password.
2. Supabase sends an email confirmation. The user must confirm it and return to the app / sign in.
3. After email authentication, Knot asks for a phone number in E.164 format (for example, `+380XXXXXXXXX`).
4. Supabase sends an SMS OTP. The app verifies it with the `phoneChange` OTP flow.
5. After successful phone verification, the app opens the Knot home screen.

The phone number is stored in Supabase Auth's protected user record, not in the publicly discoverable profile table. The current client gate uses the authenticated user's `phone` field as the completion signal. Before production, add a server-side onboarding-completion check (e.g. a trusted Edge Function / database trigger) and verify the exact behavior against the configured Supabase Auth version.

## Important production work still required

- Deep-link configuration and end-to-end testing of email confirmation / password recovery on Android and iOS
- Real conversation list and message send/receive UI backed by Postgres + Realtime
- Contact discovery with privacy-preserving lookup and consent
- Media upload/download policies and limits
- Push notifications (FCM/APNs)
- Voice/video calling infrastructure
- End-to-end encryption protocol implementation and independent security review
- Abuse reporting, blocking, moderation, rate limits, account deletion, privacy policy, and terms
- Automated tests, CI builds, store signing, and release configuration

This is a development starter, not yet a production-ready or published messenger.

## v0.2 — real one-to-one chats

The app now loads the signed-in user's conversation memberships from Postgres, displays direct conversations, supports starting a chat by another person's Knot ID, sends text messages, and listens to the `messages` Realtime stream for live updates.

Apply migrations in order:

1. `supabase/migrations/0001_initial_schema.sql`
2. `supabase/migrations/0002_real_chats.sql`

The second migration adds a secure `create_direct_chat(p_knot_id)` RPC, fixes recursive membership RLS checks, restricts read-marker updates to the `last_read_at` column, and maintains conversation timestamps when messages arrive.

### Current chat scope

- Working implementation path: authenticated one-to-one text chats.
- The other participant is found by their public Knot ID; phone and email remain in Supabase Auth and are not shown in the public profile.
- Group creation, media attachments, typing indicators, delivery/read receipts, push notifications, and calls are not implemented yet.
- Before production, add abuse controls, account deletion, retention rules, device/session management, and independent security review. Do not describe the current transport as end-to-end encrypted.
