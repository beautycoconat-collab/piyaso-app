/* User-supplied Piyaso artwork, prepared for the night-coast wallet. */
function jetonPackArtwork(tier){return `<img class="jeton-pack-art" src="assets/wallet/pack-${tier}.webp" alt="" width="600" height="420" decoding="async">`}
function jetonWalletCoin(){return '<img class="jeton-wallet-coin" src="assets/wallet/pack-0.webp" width="48" height="48" alt="">'}
function jetonWalletIcon(name){
 if(window.KiyiUIIcon&&['back','next','car','crown'].includes(name))return window.KiyiUIIcon(name);
 const paths={gift:'<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M5 12v9h14v-9M12 8v13M12 8H7.5A2.5 2.5 0 1 1 10 5.5L12 8Zm0 0h4.5A2.5 2.5 0 1 0 14 5.5L12 8Z"/>',music:'<path d="M9 18V5l12-2v13M9 9l12-2"/><ellipse cx="6" cy="18" rx="3" ry="3"/><ellipse cx="18" cy="16" rx="3" ry="3"/>',star:'<path d="m12 3 2.8 5.7 6.2.9-4.5 4.4 1.1 6.2-5.6-2.9-5.6 2.9 1.1-6.2L3 9.6l6.2-.9Z"/>',history:'<path d="M8 3H5a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h12l4 2V6a2 2 0 0 0-2-2h-7M8 2v5h7M7 11h10M7 15h7"/>',info:'<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7h.01"/>'};
 return `<svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[name]||''}</svg>`;
}
