// Load .env into process.env DETERMINISTICALLY, before any other module reads
// it. This must be the very first import in server.ts so that module-level
// reads of process.env (e.g. JWT_SECRET) always see the .env values — otherwise
// the effective secret can differ between restarts and previously-issued tokens
// stop verifying.
try {
  // Node 20.12+/22+: built-in .env loader. No dependency needed.
  process.loadEnvFile();
} catch {
  // .env is optional (e.g. in production where env vars are set directly).
}
