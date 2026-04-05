import { createContext, useCallback, useContext, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase.js'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [session, setSession] = useState(undefined) // undefined = still loading
  const [user, setUser]       = useState(null)

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      setSession(session)
      setUser(session?.user ?? null)
      // Ensure a profiles row exists (guards against partial registrations)
      if (session?.user) {
        const { data: profile } = await supabase
          .from('profiles').select('id').eq('id', session.user.id).single()
        if (!profile) {
          const fallback = session.user.user_metadata?.username
            || session.user.email?.split('@')[0]
            || `user_${session.user.id.slice(0, 6)}`
          await supabase.rpc('create_profile', { p_username: fallback })
        }
      }
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      // Only clear session on explicit sign-out — ignore transient nulls during token refresh
      if (event === 'SIGNED_OUT') {
        setSession(null)
        setUser(null)
      } else if (session) {
        setSession(session)
        setUser(session.user ?? null)
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  const signOut = useCallback(async () => {
    await supabase.auth.signOut()
    window.location.href = './index.html'
  }, [])

  return (
    <AuthContext.Provider value={{ session, user, signOut, loading: session === undefined }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
