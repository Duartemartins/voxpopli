// minidenticons@4.2.1 downloaded from https://ga.jspm.io/npm:minidenticons@4.2.1/minidenticons.js

const t=9;const n=95;const e=45;const i=5;
/**
 * @type {(str: string) => number}
 */function simpleHash(t){return t.split("").reduce(((t,n)=>(t^n.charCodeAt(0))*-i),i)>>>2}
/**
 * @type {import('.').minidenticon}
 */function minidenticon(i="",s=n,o=e,c=simpleHash){const d=c(i);const l=d%t*(360/t);return[...Array(i?25:0)].reduce(((t,n,e)=>d&1<<e%15?t+`<rect x="${e>14?7-~~(e/5):~~(e/5)}" y="${e%5}" width="1" height="1"/>`:t),`<svg viewBox="-1.5 -1.5 8 8" xmlns="http://www.w3.org/2000/svg" fill="hsl(${l} ${s}% ${o}%)">`)+"</svg>"}
/**
 * @type {void}
 */const s=globalThis.customElements?.get("minidenticon-svg")?null:globalThis.customElements?.define("minidenticon-svg",class MinidenticonSvg extends HTMLElement{static observedAttributes=["username","saturation","lightness"];static#t={};#n=false;connectedCallback(){this.#e();this.#n=true}attributeChangedCallback(){this.#n&&this.#e()}#e(){const t=MinidenticonSvg.observedAttributes.map((t=>this.getAttribute(t)||void 0));const n=t.join(",");this.innerHTML=MinidenticonSvg.#t[n]??=minidenticon(...t)}});export{minidenticon,s as minidenticonSvg};

