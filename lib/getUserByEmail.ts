import type { SupabaseClient, User } from '@supabase/supabase-js'

/**
 * Look up an auth user by email. listUsers() is paginated (default 50/page),
 * so we must paginate to avoid missing users beyond the first page.
 */
export async function getUserByEmail(
  supabase: SupabaseClient,
  email: string
): Promise<User | null> {
  const normalizedEmail = email.trim().toLowerCase()
  let page = 1
  const perPage = 1000

  while (true) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage })
    if (error) {
      throw error
    }

    const user = data.users.find(
      (u) => u.email?.trim().toLowerCase() === normalizedEmail
    )
    if (user) {
      return user
    }

    if (data.users.length < perPage) {
      return null
    }

    page++
  }
}
