const cors={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS'};
const reply=(status:number,body:unknown)=>new Response(JSON.stringify(body),{status,headers:{...cors,'Content-Type':'application/json'}});
Deno.serve(async(req:Request)=>{
 if(req.method==='OPTIONS')return new Response('ok',{headers:cors});
 if(req.method!=='POST')return reply(405,{error:'Method not allowed'});
 const base=Deno.env.get('SUPABASE_URL')!, key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
 const token=req.headers.get('Authorization');
 if(!token?.startsWith('Bearer '))return reply(401,{error:'Sign in required'});
 const userResponse=await fetch(base+'/auth/v1/user',{headers:{apikey:key,Authorization:token}});
 if(!userResponse.ok)return reply(401,{error:'Invalid session'});
 const user=await userResponse.json();
 const headers={apikey:key,Authorization:'Bearer '+key,'Content-Type':'application/json'};
 const roleResponse=await fetch(base+'/rest/v1/staff_members?user_id=eq.'+encodeURIComponent(user.id)+'&select=role,active',{headers});
 if(!roleResponse.ok)return reply(503,{error:'Unable to verify permissions'});
 const roles=await roleResponse.json();
 if(!roles.some((r:{role:string,active:boolean})=>r.role==='super_admin'&&r.active))return reply(403,{error:'Super Admin access required'});
 try{
 const body=await req.json(), allowed=['super_admin','editor','journalist','ad_manager','analyst'];
 if(typeof body.email!=='string'||!body.email.includes('@')||typeof body.password!=='string'||body.password.length<12||typeof body.name!=='string'||!body.name.trim()||!allowed.includes(body.role))return reply(400,{error:'Valid email, display name, role and password of at least 12 characters required'});
 const created=await fetch(base+'/auth/v1/admin/users',{method:'POST',headers,body:JSON.stringify({email:body.email.trim(),password:body.password,email_confirm:true})});
 const account=await created.json();
 if(!created.ok)return reply(400,{error:account.msg||account.message||'Could not create account'});
 const saved=await fetch(base+'/rest/v1/staff_members',{method:'POST',headers,body:JSON.stringify({user_id:account.id,display_name:body.name.trim(),role:body.role,active:true})});
 if(!saved.ok){await fetch(base+'/auth/v1/admin/users/'+account.id,{method:'DELETE',headers});return reply(500,{error:'Role assignment failed; account creation rolled back'});}
 return reply(200,{id:account.id,created:true});
 }catch{return reply(400,{error:'Invalid request'});}
});
