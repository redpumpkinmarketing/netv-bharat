import { createClient } from '@supabase/supabase-js';
export const supabase = createClient('https://ajaqpncrdedpeokircud.supabase.co', 'sb_publishable_CGCtMOIM-YeGkD-I-tt2iQ_kTfgyg2e');
export function unwrap({data,error}) { if(error) throw error; return data; }
export const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export const safeUrl = value => { try { const u=new URL(value); return ['https:','http:'].includes(u.protocol)?u.href:''; } catch { return ''; } };
export function paragraphs(text) {return String(text||'').split(/\n\s*\n/).filter(Boolean).map(p=>`<p>${esc(p).replace(/\n/g,'<br>')}</p>`).join('');}
