import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL      = 'https://ftryuvfdihmhlzvbpfeu.supabase.co'
const SUPABASE_ANON_KEY = 'sb_publishable_hNTtICDrKMNgAclh28BhrQ_bHTeeFB9'

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
