// Legacy D1/R2 records remain retained for controlled migration, not publicly served.
export const dynamic='force-dynamic';
export const GET=()=>Response.json({error:'Bu sürümde içerikler Piyaso hesabın üzerinden Supabase’de tutuluyor.'},{status:410});
export const POST=GET;
export const DELETE=GET;
