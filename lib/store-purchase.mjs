// Server-only boundary. Never accept client-provided credits, price or Premium duration.
export class StoreUnavailable extends Error { constructor(){super('Store verification is not connected');this.status=503} }
export async function verifyStorePurchase({provider,receipt,environment}, {verifiers={},catalog={},deployment='production'}={}){
 if(!['apple','google'].includes(provider)||!['production','sandbox'].includes(environment)||typeof receipt!=='string'||receipt.length>32768)throw Error('Invalid receipt');
 if(deployment==='production'&&environment!=='production')throw Error('Sandbox purchase cannot fund a production wallet');
 const verify=verifiers[provider];if(typeof verify!=='function')throw new StoreUnavailable();
 const signed=await verify(receipt);
 if(!signed||signed.environment!==environment||signed.provider!==provider||signed.revoked||!signed.transactionId||!signed.accountId)throw Error('Untrusted purchase');
 const product=catalog[signed.productId];if(!product)throw Error('Unknown product');
 return Object.freeze({provider,transactionId:signed.transactionId,accountId:signed.accountId,environment,productId:signed.productId,credits:product.credits||0,premiumDays:product.premiumDays||0});
}
// Caller must match accountId with authenticated owner and apply in the existing
// atomic order/ledger transaction using (provider,transactionId) idempotency.
// This module does NOT credit wallets and is NOT exposed as a payment endpoint.
