const origins=new Set(['capacitor://localhost','https://localhost','http://localhost']);
export function nativeResponse(response,origin){if(!origins.has(origin))return response;const headers=new Headers(response.headers);headers.set('Access-Control-Allow-Origin',origin);headers.append('Vary','Origin');return new Response(response.body,{status:response.status,headers})}
