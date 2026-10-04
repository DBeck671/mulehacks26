import {readFileSync} from 'node:fs';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc,getDoc,getDocs,collection,setDoc,updateDoc,deleteDoc,writeBatch,serverTimestamp} from 'firebase/firestore';
const env=await initializeTestEnvironment({projectId:'demo-sidequest-clubs',firestore:{host:'127.0.0.1',port:8090,rules:readFileSync('firestore.rules','utf8')}});
const host=env.authenticatedContext('host').firestore(), bob=env.authenticatedContext('bob').firestore(), eve=env.authenticatedContext('eve').firestore();
const anon=env.unauthenticatedContext().firestore();
const code='SQ-ABCDEFGHJKLM';
const profile={name:'Host',xp:0,questsCompleted:0};
async function create(id,visibility='public',limit=3) {
 const batch=writeBatch(host);
 batch.set(doc(host,`clubs/${id}`),{name:'Test club',visibility,hostUid:'host',memberIds:['host'],memberLimit:limit,questIds:[1,2,3],createdAt:serverTimestamp()});
 batch.set(doc(host,`clubs/${id}/private/config`),{inviteCode:code+ (id==='public'?'2':'3')});
 // Use exactly 12 characters, separate codes for each club.
 await assertFails(batch.commit());
 const valid=writeBatch(host);
 const key=id==='public'?code:'SQ-23456789ABCD';
 valid.set(doc(host,`clubs/${id}`),{name:'Test club',visibility,hostUid:'host',memberIds:['host'],memberLimit:limit,questIds:[1,2,3],createdAt:serverTimestamp()});
 valid.set(doc(host,`clubs/${id}/private/config`),{inviteCode:key});
 valid.set(doc(host,`clubCodes/${key}`),{clubId:id});
 valid.set(doc(host,`clubs/${id}/members/host`),profile);
 await assertSucceeds(valid.commit());
}
try {
 await create('public','public',2); await create('private','private',4);
 await assertFails(getDocs(collection(anon,'clubs')));
 await assertSucceeds(getDocs(collection(bob,'clubs')));
 await assertFails(getDoc(doc(bob,'clubs/private/private/config')));
 await assertFails(getDocs(collection(bob,'clubs/private/members')));
 await assertFails(getDocs(collection(bob,'clubCodes')));
 await assertSucceeds(getDoc(doc(bob,`clubCodes/${code}`)));
 const join=writeBatch(bob); join.update(doc(bob,'clubs/public'),{memberIds:['host','bob']});join.set(doc(bob,'clubs/public/members/bob'),{...profile,name:'Bob'}); await assertSucceeds(join.commit());
 await assertFails(updateDoc(doc(eve,'clubs/public'),{memberIds:['host','bob','eve']}));
 await assertFails(updateDoc(doc(bob,'clubs/public'),{memberLimit:99}));
 await assertFails(updateDoc(doc(eve,'clubs/private'),{memberIds:['host','eve']}));
 await assertFails(setDoc(doc(eve,'clubs/private/requests/eve'),{name:'Eve',status:'approved',code:''}));
 await assertFails(setDoc(doc(eve,'clubs/private/requests/eve'),{name:'Eve',status:'pending',code:'WRONG'}));
 await assertSucceeds(setDoc(doc(eve,'clubs/private/requests/eve'),{name:'Eve',status:'pending',code:''}));
 await assertFails(getDoc(doc(bob,'clubs/private/requests/eve')));
 const approve=writeBatch(host); approve.update(doc(host,'clubs/private'),{memberIds:['host','eve']});approve.update(doc(host,'clubs/private/requests/eve'),{status:'approved',code:''});approve.set(doc(host,'clubs/private/members/eve'),{...profile,name:'Eve'});await assertSucceeds(approve.commit());
 const coded=writeBatch(bob);coded.set(doc(bob,'clubs/private/requests/bob'),{name:'Bob',status:'pending',code:'SQ-23456789ABCD'});coded.update(doc(bob,'clubs/private'),{memberIds:['host','eve','bob']});coded.set(doc(bob,'clubs/private/members/bob'),{...profile,name:'Bob'});await assertSucceeds(coded.commit());
 await assertSucceeds(getDocs(collection(bob,'clubs/private/members')));
 const leave=writeBatch(bob);leave.update(doc(bob,'clubs/private'),{memberIds:['host','eve']});leave.delete(doc(bob,'clubs/private/members/bob'));await assertSucceeds(leave.commit());
 await assertFails(getDocs(collection(bob,'clubs/private/members')));
 const transfer=writeBatch(host);transfer.update(doc(host,'clubs/private'),{memberIds:['eve'],hostUid:'eve'});transfer.delete(doc(host,'clubs/private/members/host'));await assertSucceeds(transfer.commit());
 await assertFails(updateDoc(doc(host,'clubs/private'),{memberLimit:50}));
 await assertSucceeds(updateDoc(doc(eve,'clubs/private'),{memberLimit:50}));
 console.log('PASS: public join, private code/approval, capacity, private roster/code access, leave and host transfer.');
} finally {await env.cleanup();}
