
import * as custom from "./custom.js";

import {Elm} from "./Main.elm";
import {Elm as Login} from "./Home.elm";

import './style.scss';

const firebase = require('firebase/app');
require('firebase/auth');
require('firebase/firestore');

var firebaseConfig = {
    apiKey: "AIzaSyAELGSk82RWuRW_wO4S-u_Qp68B6U2b3JU",
    authDomain: "practice-b0400.firebaseapp.com",
    databaseURL: "https://practice-b0400.firebaseio.com",
    projectId: "practice-b0400",
    storageBucket: "practice-b0400.appspot.com",
    messagingSenderId: "963218471494",
    appId: "1:963218471494:web:78d9f70765d6a781"
};
// Initialize Firebase
firebase.initializeApp(firebaseConfig);

firebase.auth().getRedirectResult().then(result=>{
    if (firebase.auth().currentUser == null) {
        console.log('no user data');
    } else {
        firebase.auth().currentUser.getIdToken().then(token=>{
            console.log('token: ', token);
        });
    }
}).catch(error=>{
    console.warn(error);
});

document.getElementById('auth').addEventListener('click', ()=>{
    firebase.auth().signInWithRedirect(new firebase.auth.TwitterAuthProvider());
});

document.getElementById('logout').addEventListener('click', ()=>{
    console.log('logout');
    firebase.auth().signOut();
});
