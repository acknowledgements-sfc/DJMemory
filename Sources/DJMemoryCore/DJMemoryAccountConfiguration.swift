import Foundation

/// Shared accounts host for Mac and iPad. Same Clerk + Supabase + Vercel stack.
/// Local archive / scan / protection / import never depend on this URL being reachable.
public enum DJMemoryAccountConfiguration {
    /// Override with `DJMEMORY_ACCOUNT_URL`. Default is the live `djmemory-admin` deploy.
    /// When `accounts.djmemory.app` DNS is wired, set the env (or change default) to that host.
    public static var baseURLString: String {
        ProcessInfo.processInfo.environment["DJMEMORY_ACCOUNT_URL"]
            ?? "https://djmemory-admin.vercel.app"
    }
}
