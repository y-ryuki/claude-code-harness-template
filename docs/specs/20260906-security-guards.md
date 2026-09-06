# Security guard corrections

## Scope

Owner-requested hotfix for Git push destination checks, local API smoke requests,
published smoke results, and DevContainer firewall initialization. No public Issue
is opened, following `SECURITY.md`; the filename uses the hotfix date.

## Acceptance criteria

- A push targeting main, master, develop, release, or release/* is rejected,
  including explicit source:destination mappings and fully qualified refs.
  Explicit feature-branch pushes remain available. Ambiguous/bulk pushes fail closed.
- All API smoke requests are validated before the first request. Only HTTP(S)
  loopback origins and absolute local paths are accepted. Curl ignores user config,
  proxy settings and redirects; request headers and bodies retain their API meaning.
- Shared smoke results contain status-based evidence only: no response body,
  response headers, curl stderr, request headers/body, or arbitrary config text.
  Configuration errors replace stale results and return exit code 2.
- IPv4 and IPv6 default-deny policies are installed before rules are cleared or
  external data is requested. IPv6 is restricted to loopback in this template.
  IPv4 rules accept only IPv4 ranges. Initialization errors remain nonzero and
  retain already-installed deny policies; a policy-setting error stops immediately.
- Hook, API smoke, and firewall regression tests run locally and in CI. Audit
  success requires these behavior checks, not only configuration-file existence.

## Verification

Use synthetic inputs, stubbed curl and firewall commands, and temporary files.
No test pushes to GitHub, modifies the host firewall, or uses real credentials.
Run existing hooks/conventions, settings validation, audit, shellcheck and secret scan.
Verify real firewall behavior in an isolated Linux environment if available;
otherwise state that container-level network enforcement has not been exercised.
