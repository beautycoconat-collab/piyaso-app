// Conservative Turkish text triage, not an image/video or legal classifier.
export function reviewText(value){
 const text=String(value||'').normalize('NFKC').toLocaleLowerCase('tr');
 const reasons=[];
 if(/(?:seni|sizi)\s+(?:öldür|oldur)|(?:öldüreceğim|oldurecegim)/u.test(text))reasons.push('threat');
 if(/\b(?:\+?90\s*)?0?5\d{2}[\s-]*\d{3}[\s-]*\d{2}[\s-]*\d{2}\b/u.test(text))reasons.push('possible_personal_data');
 if((text.match(/https?:\/\//g)||[]).length>5)reasons.push('spam');
 return {decision:reasons.length?'review':'undetermined',reasons};
}
export function reviewMedia(){return {decision:'review',reasons:['visual_classifier_not_connected']}}
